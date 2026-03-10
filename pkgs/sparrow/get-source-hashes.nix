{ writeScriptBin
, bash
, nix 
}:
writeScriptBin "sparrow-get-source-hashes" ''
  #! ${bash}/bin/bash

  if [ "$#" -eq 0 ]; then
    echo "Usage: sparrow-get-source-hashes VERSION"
    exit 1
  fi

  echo "x86_64..."
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrowwallet-$@-x86_64.tar.gz)

  echo "aarch64..."
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrowwallet-$@-aarch64.tar.gz)
''
