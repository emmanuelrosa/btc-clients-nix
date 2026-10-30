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
    x86_64-linux = "sha256-HdXVGyFyTx/lfZUiOoIjqb5OEjx0lOQikOFS4+4QAGg=";
    aarch64-linux = "sha256-JNI1Leaca8imogQ104VtCi77N0RD68o/xmNQkyF45DQ=";
  }."${stdenvNoCC.hostPlatform.system}";
in stdenvNoCC.mkDerivation rec {
  pname = "playit";
  version = "1.2.0";

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
