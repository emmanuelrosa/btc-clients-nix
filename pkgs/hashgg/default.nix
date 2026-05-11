{ stdenvNoCC
, runCommand
, lib
, fetchFromGitHub
, makeWrapper
, writeScriptBin
, writeText
, buildFHSEnv
, autoPatchelfHook
, makeDesktopItem
, copyDesktopItems
, imagemagick
, bash
, coreutils
, nodejs
, curl
, netcat
, jq
, yq-go
, procps
, openssh
, playit
, address ? "127.0.0.1"
, port ? 3000
, stratumPort ? 23335
, dataDirectory ? "$HOME/.config/hashgg"
, label ? null
}:
let 
  version = "0.3.0.0";

  # Exposes playitd to PATH
  playitd = runCommand "playitd" {} ''
    mkdir -p $out/bin
    cp ${playit}/share/playit/bin/playitd $out/bin/
  ''; 

  # Since Docker/Podman isn't being used,
  # the socat proxy isn't needed.
  # In fact, it can't be used because the port it attempts
  # to bind to would already be in use.
  fake-socat = writeScriptBin "socat" "
    sleep infinity
  ";

  # A fake StartOS configuration.
  # It makes hashgg happy.
  start9Config = writeText "config.yaml" ''
    advanced:
      datum_stratum_port: ${builtins.toString stratumPort}
    playit:
      secret_key:
  '';

  app = stdenvNoCC.mkDerivation {
    pname = "hashgg-app";
    inherit version;

    src = fetchFromGitHub {
      owner = "paulscode";
      repo = "hashgg";
      rev = "v${version}";
      hash = "sha256-m5XuY3hD/NVbIthvh9fl5HgfeX1gl+28tPMZIu6q/jI=";
    };

    dontBuild = true;

    nativeBuildInputs = [
      makeWrapper
      autoPatchelfHook
      imagemagick
      copyDesktopItems
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/lib/hashgg
      cp -r ./app/backend $out/lib/hashgg/
      cp -r ./app/frontend $out/lib/hashgg/
      cp ./docker_entrypoint.sh $out/bin/
      cp ./check-tunnel.sh $out/bin/
      cp ./check-datum.sh $out/bin/

      wrapProgram $out/bin/docker_entrypoint.sh \
        --prefix PATH : ${lib.makeBinPath [ yq-go fake-socat nodejs ]}

      wrapProgram $out/bin/check-tunnel.sh \
        --prefix PATH : ${lib.makeBinPath [ jq curl ]}

      wrapProgram $out/bin/check-datum.sh \
        --prefix PATH : ${lib.makeBinPath [ coreutils yq-go netcat ]}

      substituteInPlace $out/lib/hashgg/backend/server.js \
        --replace-fail "server.listen(PORT, '0.0.0.0', () => {" "server.listen(PORT, '${address}', () => {"

      substituteInPlace $out/lib/hashgg/backend/server.js \
        --replace-fail 'const PORT = 3000' 'const PORT = ${builtins.toString port}'

      for n in 16 24 32 48 64 96 128 256; do
        size=$n"x"$n
        mkdir -p $out/share/icons/hicolor/$size/apps
        convert ./icon.png -resize $size $out/share/icons/hicolor/$size/apps/hashgg.png
      done;

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = if label == null then "hashgg" else "hashgg-${builtins.hashString "sha1" label}";
        icon = "hashgg";
        type = "Link";
        url = "http://${address}:${builtins.toString port}";
        desktopName = if label == null then "HashGG" else "HashGG (${label})";
      })
    ];
  };
in buildFHSEnv {
  pname = "hashgg";
  inherit version;

  targetPkgs = pkgs: [
    coreutils
    procps
    openssh
    app
  ];

  extraPreBwrapCmds = ''
    if [ ! -d ${dataDirectory} ]; then
      mkdir -p ${dataDirectory}
    fi
  '';

  extraBuildCommands = ''
    mkdir -p $out/usr/local
    ln -s $out/usr/lib $out/usr/local/lib
    ln -s $out/usr/bin $out/usr/local/bin
  '';

  extraInstallCommands = ''
    ln -sf ${app}/share $out
  '';

  profile = ''
    export DATUM_STRATUM_PORT=${builtins.toString stratumPort}
  '';

  extraBwrapArgs = [
    "--tmpfs /root"
    "--bind ${dataDirectory} /root/data"
    "--symlink ${start9Config} /root/start9/config.yaml"
  ];

  runScript = "/bin/docker_entrypoint.sh";

  meta = with lib; {
    description = "Expose your Datum Gateway stratum port to the internet via playit.gg -- sovereign hash routing for NixOS, no port forwarding required.";
    homepage = "https://github.com/paulscode/hashgg";
    license = licenses.mit;

    maintainers = with maintainers; [
      emmanuelrosa
    ];

    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    mainProgram = "hashgg";
  };
}

