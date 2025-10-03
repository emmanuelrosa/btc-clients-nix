{
  stdenvNoCC,
  stdenv,
  lib,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
  buildFHSEnv,

  # temurin JDK dependencies
  alsa-lib,
  fontconfig,
  freetype,
  libffi,
  xorg,
  zlib,
  cups,
  cairo,
  glib,
  gtk3,
  libGL,

  # tor dependencies
  libevent,
  openssl,
  xz,
  zstd,
  scrypt,
  libseccomp,
  systemd,
  libcap,

  imagemagick,
  gnupg,
  libusb1,
  pcsclite,
  udevCheckHook,
}:

let
  pname = "sparrow";
  version = "2.3.0";

  sparrowArch =
    {
      x86_64-linux = "x86_64";
      aarch64-linux = "aarch64";
    }
    ."${stdenvNoCC.hostPlatform.system}";

  # nixpkgs-update: no auto update
  src = fetchurl {
    url = "https://github.com/sparrowwallet/${pname}/releases/download/${version}/sparrowwallet-${version}-${sparrowArch}.tar.gz";
    hash =
      {
        x86_64-linux = "sha256-PmZpxyTXzQMIAGH0edxEHCwzb+k8HBJYXnfyZkpCnoM=";
        aarch64-linux = "sha256-A61KB2KhyKCGLMrcIs4bJk7pqcfKHe8Vqn3b4bxwysM=";
      }
      ."${stdenvNoCC.hostPlatform.system}";

    # nativeBuildInputs, downloadToTemp, and postFetch are used to verify the signed upstream package.
    # The signature is not a self-contained file. Instead the SHA256 of the package is added to a manifest file.
    # The manifest file is signed by the owner of the public key, Craig Raw.
    # Thus to verify the signed package, the manifest is verified with the public key,
    # and then the package is verified against the manifest.
    # The public key is obtained from https://keybase.io/craigraw/pgp_keys.asc
    # and is included in this repo to provide reproducibility.
    nativeBuildInputs = [ gnupg ];
    downloadToTemp = true;

    postFetch = ''
      pushd $(mktemp -d)
      export GNUPGHOME=$PWD/gnupg
      mkdir -m 700 -p $GNUPGHOME
      ln -s ${manifest} ./manifest.txt
      ln -s ${manifestSignature} ./manifest.txt.asc
      ln -s $downloadedFile ./sparrowwallet-${version}-${sparrowArch}.tar.gz
      gpg --import ${publicKey}
      gpg --verify manifest.txt.asc manifest.txt
      sha256sum -c --ignore-missing manifest.txt
      popd
      mv $downloadedFile $out
    '';
  };

  manifest = fetchurl {
    url = "https://github.com/sparrowwallet/${pname}/releases/download/${version}/${pname}-${version}-manifest.txt";
    hash = "sha256-QNlbu9Y7kJ0fvqHubyP8/yAIEiw6mWzVnsyJTXJcWqk=";
  };

  manifestSignature = fetchurl {
    url = "https://github.com/sparrowwallet/${pname}/releases/download/${version}/${pname}-${version}-manifest.txt.asc";
    hash = "sha256-H3PDTGypdqhCtCXTecwLUNrlhGvxESDaKb4O2LOXXbA=";
  };

  publicKey = ./publickey.asc;

  sparrow-icons = stdenvNoCC.mkDerivation {
    inherit version src;
    pname = "sparrow-icons";
    nativeBuildInputs = [ imagemagick ];

    installPhase = ''
      for n in 16 24 32 48 64 96 128 256; do
        size=$n"x"$n
        mkdir -p $out/hicolor/$size/apps
        convert lib/Sparrow.png -resize $size $out/hicolor/$size/apps/sparrow-desktop.png
        done;
    '';
  };

  sparrow-unwrapped = stdenvNoCC.mkDerivation {
    inherit version src;
    pname = "sparrow-unwrapped";
    nativeBuildInputs = [
      copyDesktopItems
      udevCheckHook
    ];

    desktopItems = [
      (makeDesktopItem {
        name = "sparrow-desktop";
        exec = "sparrow-desktop";
        icon = "sparrow-desktop";
        desktopName = "Sparrow Bitcoin Wallet";
        genericName = "Bitcoin Wallet";
        categories = [
          "Finance"
          "Network"
        ];
        mimeTypes = [
          "application/psbt"
          "application/bitcoin-transaction"
          "x-scheme-handler/bitcoin"
          "x-scheme-handler/auth47"
          "x-scheme-handler/lightning"
        ];
        startupWMClass = "Sparrow";
      })
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/etc/udev
      cp bin/Sparrow $out/bin/
      cp -r lib/ $out/

      mkdir -p $out/share/icons
      ln -s ${sparrow-icons}/hicolor $out/share/icons

      mkdir -p $out/etc/udev/
      ln -s $out/lib/runtime/conf/udev $out/etc/udev/rules.d

      runHook postInstall
    '';

    doInstallCheck = true;
  };
in
buildFHSEnv {
  pname = "sparrow-desktop";
  inherit version;
  runScript = "${sparrow-unwrapped}/bin/Sparrow";

  targetPkgs = pkgs: [
    (lib.getLib stdenv.cc.cc) # libstdc++.so.6
    alsa-lib
    fontconfig
    freetype
    libffi
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libXxf86vm
    zlib
    cups
    cairo
    glib
    gtk3
    libGL
    libevent
    openssl
    xz
    zstd
    scrypt
    libseccomp
    systemd
    libcap
    libusb1
    pcsclite
  ];

  extraInstallCommands = ''
    mkdir -p $out/share
    ln -sf ${sparrow-unwrapped}/share/applications $out/share
    ln -sf ${sparrow-unwrapped}/share/icons $out/share
    ln -sf ${sparrow-unwrapped}/etc $out
  '';

  meta = with lib; {
    description = "Modern desktop Bitcoin wallet application supporting most hardware wallets and built on common standards such as PSBT, with an emphasis on transparency and usability";
    homepage = "https://sparrowwallet.com";
    sourceProvenance = with sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    license = licenses.asl20;
    maintainers = with maintainers; [
      emmanuelrosa
      msgilligan
      _1000101
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "sparrow-desktop";
  };
}
