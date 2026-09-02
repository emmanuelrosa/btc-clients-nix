{
  lib,
  stdenvNoCC,
  fetchurl,
  python3,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rpcauth";
  version = "31.1";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/bitcoin/bitcoin/refs/tags/v${finalAttrs.version}/share/rpcauth/rpcauth.py";
    hash = "sha256-3WFc3/KG8zrqq0QEmoVJc9xszUzenl+LM0GWwDUqFBY=";
  };

  dontUnpack = true;

  buildInputs = [
    python3
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install ${finalAttrs.src} $out/bin/rpcauth
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
