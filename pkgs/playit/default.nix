{ stdenvNoCC
, lib
, dpkg
, fetchurl
}: let
  arch = {
    x86_64-linux = "amd64";
    aarch64-linux = "arm64";
  }."${stdenvNoCC.hostPlatform.system}";

  hash = {
    x86_64-linux = "sha256-hGK/+VaW5uA0SCEiQzjCIxMyrnm49XPJbB/cKODR5sM=";
    aarch64-linux = "sha256-n7XTNaLPzMAZzUkjuyA8OyU/92JcuxiZ43FDJr0MbD8=";
  }."${stdenvNoCC.hostPlatform.system}";
in stdenvNoCC.mkDerivation rec {
  pname = "playit";
  version = "1.0.4";

  src = fetchurl {
    inherit hash;
    url = "https://github.com/playit-cloud/playit-agent/releases/download/v${version}/playit_${arch}.deb";
  };

  nativeBuildInputs = [ dpkg ];

  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install ./opt/playit/playitd $out/bin/
    install ./opt/playit/agent $out/bin/playit
    runHook postInstall
  '';

  meta = {
    description = "Use playit to create public addresses for your local servers.";
    longDescription = "This package uses playit.gg's Debian package instead of compiling from source. This avoids needing to download a huge Rust toolchain.";
    homepage = "https://playit.gg/";
    mainProgram = "playitd";
    license = lib.licenses.bsd2;
    maintainers = with lib.maintainers; [ emmanuelrosa ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
