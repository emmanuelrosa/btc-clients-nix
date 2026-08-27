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

  echo "Downloading sparrowwallet-$@-x86_64.tar.gz"
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrowwallet-$@-x86_64.tar.gz)

  echo "Downloading sparrowwallet-$@-aarch64.tar.gz"
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrowwallet-$@-aarch64.tar.gz)

  echo "Downloading the manifest"
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrow-$@-manifest.txt)

  echo "Downloading the manifest signature"
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/sparrowwallet/sparrow/releases/download/$@/sparrow-$@-manifest.txt.asc)
''
