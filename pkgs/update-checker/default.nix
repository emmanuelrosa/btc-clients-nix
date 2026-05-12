{ stdenv
, coreutils
, writeScriptBin
, bash
, gnused
, curl
, jq
, bisq
, bisq2
, sparrow
, bitcoin-tui
, rpcauth
, datum_gateway
, playit
, hashgg
}: let
    checkForUpdate = {
      package
      , owner
      , repo
      , versionConverter ? "tee"
      , allowPrerelease ? false
      }: let
        prereleaseText = if allowPrerelease then "true" else "false";
      in ''
    echo "Checking ${package.pname} for update..."

    local_version="${package.version}"
    remote_version=$(${curl}/bin/curl -s https://api.github.com/repos/${owner}/${repo}/releases| ${jq}/bin/jq '.[] | {tag_name,prerelease} | select(.prerelease==${prereleaseText}) | limit(1;.[])' | ${gnused}/bin/sed -e 's/^\"//g' -e 's/\"$//g' -e 's/Release //g' | ${versionConverter} | head -n 1)

    if [ "$local_version" == "$remote_version" ]
    then
      echo "No update found."
    else
      echo "Update found! Local: $local_version, Remote: $remote_version"
    fi

    echo
    '';
in writeScriptBin "update-checker" ''
    #! ${bash}/bin/bash

    ${checkForUpdate { package = bisq; owner = "bisq-network"; repo = "bisq"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}

    ${checkForUpdate { package = bisq2; owner = "bisq-network"; repo = "bisq2"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}

    ${checkForUpdate { package = sparrow; owner = "sparrowwallet"; repo = "sparrow"; }}

    ${checkForUpdate { package = bitcoin-tui; owner = "janb84"; repo = "bitcoin-tui"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}

    ${checkForUpdate { package = rpcauth; owner = "bitcoinknots"; repo = "bitcoin"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}

    ${checkForUpdate { package = datum_gateway; owner = "OCEAN-xyz"; repo = "datum_gateway"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}

    ${checkForUpdate { package = playit; owner = "playit-cloud"; repo = "playit-agent"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; allowPrerelease = true; }}

    ${checkForUpdate { package = hashgg; owner = "paulscode"; repo = "hashgg"; versionConverter = "${gnused}/bin/sed -e 's/^v//g'"; }}
''
