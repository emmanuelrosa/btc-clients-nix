{ writeScriptBin
, bash
, nix 
}:
writeScriptBin "playit-get-source-hashes" ''
  #! ${bash}/bin/bash

  if [ "$#" -eq 0 ]; then
    echo "Usage: playit-get-source-hashes VERSION"
    exit 1
  fi

  echo "x86_64..."
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/playit-cloud/playit-agent/releases/download/v$@/playit_amd64.deb)

  echo "aarch64..."
  ${nix}/bin/nix hash convert --hash-algo sha256 --to sri $(${nix}/bin/nix-prefetch-url https://github.com/playit-cloud/playit-agent/releases/download/v$@/playit_arm64.deb)
''

