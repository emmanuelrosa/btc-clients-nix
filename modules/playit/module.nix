{ config
, lib
, pkgs
, ...
}: 
with lib;
let
  cfg = config.services.playit;
in {
  options.services.playit = {
    enable = mkEnableOption "playit, Host game servers from your own computer and let friends join from anywhere. No port forwarding required..";

    package = mkOption {
      type = types.package;
      description = "The playit package.";
    };

    user = mkOption {
      type = types.str;
      default = "playit";
      example = "playit";
      description = "The user used to run playit";
    };

    group = mkOption {
      type = types.str;
      default = "playit";
      example = "playit";
      description = "The group used to run playit";
    };

    dataDirectory = mkOption {
      type = types.path;
      default = "/var/lib/playit";
      example = "/var/lib/playit";
      description = "The path where the playit daemon stores data; Namely the secret and Unix domain socket file.";
    };
  };

  config = let
    socketPath = "${cfg.dataDirectory}/playit.socket";

    playit-agent = pkgs.stdenvNoCC.mkDerivation rec {
      pname = "playit-agent";
      version = cfg.package.version;
      src = cfg.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin
        makeWrapper ${src}/share/playit/bin/agent $out/bin/playit \
          --add-flags "--socket-path ${socketPath}"
      '';
    };
  in lib.mkIf cfg.enable {
    environment.systemPackages = [ playit-agent ];

    users.users."${cfg.user}" = {
      group = cfg.group;
      description = "playit.gg user";
      isSystemUser = true;
    };

    users.groups."${cfg.group}" = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDirectory} 770 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.playitd = {
      description = "Playit daemon";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-pre.target" ];
      after = [ "network-pre.target"
                "NetworkManager.service"
                "systemd-resolved.service"
              ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        Restart = "on-failure";
        ReadWritePaths = [ cfg.dataDirectory ];
        ExecStart="${cfg.package}/share/playit/bin/playitd --secret-path ${cfg.dataDirectory}/playit.toml --socket-path ${socketPath}";
      };
    };

  meta.maintainers = with maintainers; [ emmanuelrosa ];
  };
}
