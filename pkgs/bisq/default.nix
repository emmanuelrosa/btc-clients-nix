{ stdenv
, lib
, makeWrapper
, fetchurl
, makeDesktopItem
, copyDesktopItems
, imagemagick
, openjdk21
, dpkg
, writeScript
, bash
, stripJavaArchivesHook
, zip
, unzip
, procps
, coreutils
, patchelf

# Dependencies for bundled Tor
, glibc
, libz
}:

let
  version = "1.10.12";
  archiveName = "Bisq-64bit-${version}.deb";
  jdk = openjdk21.override { enableJavaFX = true; };

  bisq-launcher = args: writeScript "bisq-launcher" ''
    #! ${bash}/bin/bash
    PATH="${lib.makeBinPath [ coreutils procps ]}:$PATH"

    # This is just a comment to convince Nix that this package
    # needs Tor's dependencies to execute the bundled Tor binary.
    # ${glibc} ${libz}

    rm -fR $HOME/.local/share/Bisq/btc_mainnet/tor

    classpath=@out@/lib/desktop.jar:@out@/lib/*

    exec "${jdk}/bin/java" -Djpackage.app-version=@version@ -XX:MaxRAM=8g -Xss1280k -XX:+UseG1GC -XX:MaxHeapFreeRatio=10 -XX:MinHeapFreeRatio=5 -XX:+UseStringDeduplication -Djava.net.preferIPv4Stack=true --add-exports=javafx.graphics/com.sun.javafx.scene=ALL-UNNAMED --add-exports=javafx.controls/com.sun.javafx.scene.control=ALL-UNNAMED --add-exports=javafx.controls/com.sun.javafx.scene.control.behavior=ALL-UNNAMED --add-opens=javafx.controls/javafx.scene.control.skin=ALL-UNNAMED -classpath $classpath ${args} bisq.desktop.app.BisqAppMain "$@"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "bisq-desktop";

  src = fetchurl {
    url = "https://github.com/bisq-network/bisq/releases/download/v${finalAttrs.version}/${archiveName}";
    hash = "sha256-tVJ60VgrY74GABfSPESc4xFPuGG3Hi7h20gHNc8WhyA=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    dpkg
    imagemagick
    makeWrapper
    stripJavaArchivesHook
    zip
    unzip
    patchelf
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "Bisq";
      exec = "bisq-desktop";
      icon = "bisq";
      desktopName = "Bisq ${finalAttrs.version}";
      genericName = "Decentralized bitcoin exchange";
      categories = [ "Network" "P2P" ];
    })

    (makeDesktopItem {
      name = "Bisq-hidpi";
      exec = "bisq-desktop-hidpi";
      icon = "bisq";
      desktopName = "Bisq ${finalAttrs.version} (HiDPI)";
      genericName = "Decentralized bitcoin exchange";
      categories = [ "Network" "P2P" ];
    })
  ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  preUnpack = let
    signature = fetchurl {
      url = "https://github.com/bisq-network/bisq/releases/download/v${finalAttrs.version}/${archiveName}.asc";
      hash = "sha256-1X1KcU8Los0P3veEDFlk1IAyxKaDT2QOiTIYJhgM6fU=";
    };

    publicKey = {
      "E222AA02" = fetchurl {
        url = "https://github.com/bisq-network/bisq/releases/download/v${finalAttrs.version}/E222AA02.asc";
        hash = "sha256-a+fUJT8nXqhOIULiXxdqVoTymE4qBIHiU7i0YJpI1RU=";
      };

      "387C8307" = fetchurl {
        url = "https://github.com/bisq-network/bisq/releases/download/v${finalAttrs.version}/387C8307.asc";
        hash = "sha256-9tdyU9ezFRINlInvvAj6JrUQB8i4LIs9q7ZWQhDaenU=";
      };
    };
  in ''
    pushd $(mktemp -d)
    export GNUPGHOME=./gnupg
    mkdir -m 700 -p $GNUPGHOME
    ln -s $src ./${archiveName}
    ln -s ${signature} ./signature.asc
    gpg --import ${publicKey."E222AA02"}
    gpg --import ${publicKey."387C8307"}
    gpg --batch --verify signature.asc ${archiveName}
    popd
  '';

  buildPhase = let
    torJarName = "tor-1.0.1";
  in ''
    # Prepare the bundled Tor binary to run on NixOS
    # within the Bisq Tor sandbox, "sandy".
    # See https://github.com/bisq-network/sandy

    mkdir ${torJarName}
    mkdir tor-zip

    # Unpack the .jar containing Tor.
    pushd ${torJarName}
    unzip ../opt/bisq/lib/app/${torJarName}.jar
    popd

    # Unpack the .zip containing the Tor binary.
    pushd tor-zip
    unzip ../${torJarName}/tor.zip

    # Copy all dependencies the OS is supposed to provide,
    # except ld, because they won't be accessible
    # from within the sandbox at their /nix/store locations
    interpreter="$(< "$NIX_CC/nix-support/dynamic-linker")"
    patchelf --set-interpreter "$interpreter" tor

    cp -L ${glibc}/lib/libc.so.6 ./
    cp -L ${glibc}/lib/libdl.so.2 ./
    cp -L ${glibc}/lib/libpthread.so.0 ./
    cp -L ${glibc}/lib/libm.so.6 ./
    cp -L ${libz}/lib/libz.so.1 ./

    # Repack the .zip
    zip -r ../${torJarName}/tor.zip . 
    popd

    # Repack the .jar
    pushd ${torJarName}
    zip -r ../opt/bisq/lib/app/${torJarName}.jar .
    popd
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin
    cp -r opt/bisq/lib/app $out/lib

    install -D -m 777 ${bisq-launcher ""} $out/bin/bisq-desktop
    substituteAllInPlace $out/bin/bisq-desktop

    install -D -m 777 ${bisq-launcher "-Dglass.gtk.uiScale=2.0"} $out/bin/bisq-desktop-hidpi
    substituteAllInPlace $out/bin/bisq-desktop-hidpi

    for n in 16 24 32 48 64 96 128 256; do
      size=$n"x"$n
      convert opt/bisq/lib/Bisq.png -resize $size bisq.png
      install -Dm644 -t $out/share/icons/hicolor/$size/apps bisq.png
    done;

    runHook postInstall
  '';

  meta = with lib; {
    description = "Decentralized bitcoin exchange network";
    homepage = "https://bisq.network";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    license = licenses.mit;
    maintainers = with maintainers; [ emmanuelrosa ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "bisq-desktop";
  };
})
