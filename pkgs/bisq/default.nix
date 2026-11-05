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
, tor
, zip
, unzip
, procps
, coreutils
}:

let
  version = "1.10.11";
  archiveName = "Bisq-64bit-${version}.deb";
  jdk = openjdk21.override { enableJavaFX = true; };

  bisq-launcher = args: writeScript "bisq-launcher" ''
    #! ${bash}/bin/bash
    PATH="${lib.makeBinPath [ coreutils procps ]}:$PATH"

    # This is just a comment to convince Nix that Tor is a
    # runtime dependency; The Tor binary is in a *.jar file,
    # whereas Nix only scans for hashes in uncompressed text.
    # ${bisq-tor}

    rm -fR $HOME/.local/share/Bisq/btc_mainnet/tor

    classpath=@out@/lib/desktop.jar:@out@/lib/*

    exec "${jdk}/bin/java" -Djpackage.app-version=@version@ -XX:MaxRAM=8g -Xss1280k -XX:+UseG1GC -XX:MaxHeapFreeRatio=10 -XX:MinHeapFreeRatio=5 -XX:+UseStringDeduplication -Djava.net.preferIPv4Stack=true --add-exports=javafx.graphics/com.sun.javafx.scene=ALL-UNNAMED --add-exports=javafx.controls/com.sun.javafx.scene.control=ALL-UNNAMED --add-exports=javafx.controls/com.sun.javafx.scene.control.behavior=ALL-UNNAMED --add-opens=javafx.controls/javafx.scene.control.skin=ALL-UNNAMED -classpath $classpath ${args} bisq.desktop.app.BisqAppMain --useTorSandbox=false "$@"
  '';

  bisq-tor = writeScript "bisq-tor" ''
    #! ${bash}/bin/bash

    exec ${tor}/bin/tor "$@"
  '';
in
stdenv.mkDerivation (finalAttrs: {
  inherit version;
  pname = "bisq-desktop";

  src = fetchurl {
    url = "https://github.com/bisq-network/bisq/releases/download/v${finalAttrs.version}/${archiveName}";
    hash = "sha256-wwtd8pp467YoKiqu/FWj+wxWJsBKu+Nq+Je+cv5RtM0=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    dpkg
    imagemagick
    makeWrapper
    stripJavaArchivesHook
    zip
    unzip
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
      hash = "sha256-3hHMOeqsCdsp8JgvoKtB6KHI+/cWikbPnoI0EjEV0O4=";
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
    torJarName = "tor-1.0.0";
  in ''
    # Replace the embedded Tor binary (which is in a Tar archive)
    # with one from Nixpkgs.

    mkdir ${torJarName}
    mkdir tor-zip

    pushd ${torJarName}
    unzip ../opt/bisq/lib/app/${torJarName}.jar
    popd

    pushd tor-zip
    unzip ../${torJarName}/tor.zip
    rm tor
    cp -L ${bisq-tor} ./tor
    zip -r ../${torJarName}/tor.zip . 
    popd

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
