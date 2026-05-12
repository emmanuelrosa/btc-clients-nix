{ config
, lib
, pkgs
, ...
}: 
with lib;
let
  cfg = config.services.hashgg;
  dgCfg = config.services.datum_gateway;
in {
  options.services.hashgg = {
    enable = mkEnableOption "hashgg, Expose your Datum Gateway stratum port(s) to the internet. Requires the datum_gateway NixOS module.";

    package = mkOption {
      type = types.package;
      description = "The hashgg package.";
    };

    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "127.0.0.1";
      description = "The address to listen on.";
    };

    port = mkOption {
      type = types.port;
      default = 3000;
      example = 3000;
      description = "The starting HTTP port number for hashgg instances. By default, 3001 for the pool mining instance and 3000 for the solo mining instance.";
    };

    user = mkOption {
      type = types.str;
      default = "hashgg";
      example = "hashgg";
      description = "The user used to run hashgg";
    };

    group = mkOption {
      type = types.str;
      default = "hashgg";
      example = "hashgg";
      description = "The group used to run hashgg";
    };

    dataDirectory = mkOption {
      type = types.path;
      default = "/var/lib/hashgg";
      example = "/var/lib/hashgg";
      description = "The path where hashgg stores its data.";
    };
  };

  config = let
    mkLauncher = package: pkgs.runCommand "hashgg-launcher" {} ''
      mkdir -p $out
      ln -s ${package}/share $out/share
    ''; 

    # Which instances to *exclude*.
    disabledInstances = {
      both = [];
      solo = [ "pool" ];
      pool = [ "solo" ];
    }."${dgCfg.instances}";

    instances = builtins.removeAttrs {
      solo = rec {
        dataDirectory = "${cfg.dataDirectory}/${dgCfg.network}/solo";
        port = cfg.port;
        datum-gateway-service = "datum_gateway-solo.service";

        package = cfg.package.override {
          address = cfg.address;
          port = cfg.port;
          stratumPort = dgCfg.stratum.port;
          label = "solo mining";
          inherit dataDirectory;
        };

        launcher = mkLauncher package;
      };

      pool = rec {
        dataDirectory = "${cfg.dataDirectory}/${dgCfg.network}/pool";
        port = cfg.port + 1;
        datum-gateway-service = "datum_gateway-pool.service";

        package = cfg.package.override {
          address = cfg.address;
          port = cfg.port + 1;
          stratumPort = dgCfg.stratum.port + 1;
          label = "pool mining";
          inherit dataDirectory;
        };

        launcher = mkLauncher package;
      };
    } disabledInstances;

    # A data directory is created for each *enabled* instance.
    dataDirs = builtins.mapAttrs
      (instance: instanceCfg: instanceCfg.dataDirectory) instances;

    services = builtins.listToAttrs
      (builtins.map
        (instance: { name = "hashgg-${instance}"; value = instances."${instance}"; }) (builtins.attrNames instances)
      );
  in lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = dgCfg.enable;
        message = "The hashgg NixOS module requires the datum_gateway NixOS module to be enabled.";
      }

      {
        assertion = !(cfg.user == "");
        message = "The hashgg user is required.";
      }

      {
        assertion = !(cfg.group == "");
        message = "The hashgg group is required.";
      }
    ];

    environment.systemPackages = builtins.attrValues
      (builtins.mapAttrs
        (instance: instanceCfg: instanceCfg.launcher)
        instances);

    users.users."${cfg.user}" = {
      group = cfg.group;
      description = "hashgg user";
      isSystemUser = true;
    };

    users.groups."${cfg.group}" = {};

    systemd.tmpfiles.rules = builtins.attrValues (builtins.mapAttrs
      (instance: dataDir: "d ${dataDir} 770 ${cfg.user} ${cfg.group} -")
      dataDirs);

    systemd.services = builtins.mapAttrs (instance: instanceCfg: {
      description = "hashgg server";
      wantedBy = [ "multi-user.target" ];
      requires = [ instanceCfg.datum-gateway-service ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        Restart = "on-failure";
        ReadWritePaths = [ instanceCfg.dataDirectory ];
        ExecStart="${instanceCfg.package}/bin/hashgg";
      };
    }) services;
  };

  meta.maintainers = with lib.maintainers; [ emmanuelrosa ];
}
