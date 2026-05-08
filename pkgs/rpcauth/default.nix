{
  lib,
  stdenvNoCC,
  fetchurl,
  fetchFromGitHub,
  cmake,
  python3,
  gnupg,
  # Signatures from the following GPG public keys checked during verification of the source code.
  # The list can be found at https://github.com/bitcoinknots/guix.sigs/tree/knots/builder-keys
  builderKeys ? [
    "1A3E761F19D2CC7785C5502EA291A2C45D0C504A" # luke-jr.gpg
    "DAED928C727D3E613EC46635F5073C4F4882FFFC" # leo-haf.gpg
  ],
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rpcauth";
  version = "29.3.knots20260210";

  src = fetchurl {
    url = "https://bitcoinknots.org/files/29.x/${finalAttrs.version}/bitcoin-${finalAttrs.version}.tar.gz";
    # hash retrieved from signed SHA256SUMS
    hash = "sha256-CO87KbC6W+eMGyBipuwIxHndNqH4PS4PqbKk7JRdToo=";
  };

  nativeBuildInputs = [
    gnupg
  ];

  buildInputs = [
    python3
  ];

  preUnpack =
    let
      majorVersion = lib.versions.major finalAttrs.version;

      publicKeys = fetchFromGitHub {
        owner = "bitcoinknots";
        repo = "guix.sigs";
        rev = "e34c3262de92940f4dc35e67abed84499c670af2";
        sha256 = "sha256-Zrhe7xK/7YnIfyXlMd/jpO6Ab1dNVK0S1vwdhhH3Xuc=";
      };

      checksums = fetchurl {
        url = "https://bitcoinknots.org/files/${majorVersion}.x/${finalAttrs.version}/SHA256SUMS";
        hash = "sha256-fLqGSe8/s4Ikd991rW/z8CH7UMMjvOjTHqRBwEgSD/w=";
      };

      signatures = fetchurl {
        url = "https://bitcoinknots.org/files/${majorVersion}.x/${finalAttrs.version}/SHA256SUMS.asc";
        hash = "sha256-Z6TTVKxr30OO37ve+4MrZHolo46prUVCB25kK1jLlGk=";
      };

      verifyBuilderKeys =
        let
          script = publicKey: ''
            echo "Checking if public key ${publicKey} signed the checksum file..."
            grep "^\[GNUPG:\] VALIDSIG .* ${publicKey}$" verify.log > /dev/null
            echo "OK"
          '';
        in
        builtins.concatStringsSep "\n" (map script builderKeys);
    in
    ''
      pushd $(mktemp -d)
      export GNUPGHOME=$PWD/gnupg
      mkdir -m 700 -p $GNUPGHOME
      gpg --no-autostart --batch --import ${publicKeys}/builder-keys/*
      ln -s ${checksums} ./SHA256SUMS
      ln -s ${signatures} ./SHA256SUMS.asc
      ln -s $src ./bitcoin-${finalAttrs.version}.tar.gz
      gpg --no-autostart --batch --verify --status-fd 1 SHA256SUMS.asc SHA256SUMS > verify.log
      ${verifyBuilderKeys}
      echo "Checking ${checksums} for bitcoin-${finalAttrs.version}.tar.gz..."
      grep bitcoin-${finalAttrs.version}.tar.gz SHA256SUMS > SHA256SUMS.filtered
      echo "Verifying the checksum of bitcoin-${finalAttrs.version}.tar.gz..."
      sha256sum -c SHA256SUMS.filtered
      popd
    '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install share/rpcauth/rpcauth.py $out/bin/rpcauth
    runHook postInstall
  '';

  meta = {
    description = "A utility to generate bitcoind RPC API user/password pairs.";
    longDescription = "The implementation in this package is obtained from Bitcoin Knots.";
    homepage = "https://bitcoinknots.org/";
    changelog = "https://github.com/bitcoinknots/bitcoin/blob/v${finalAttrs.version}/doc/release-notes.md";
    maintainers = with lib.maintainers; [
      emmanuelrosa
    ];
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
