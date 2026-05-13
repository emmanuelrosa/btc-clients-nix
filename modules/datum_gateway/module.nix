{ config
, lib
, pkgs
, ...
}: 
with lib;
let
  cfg = config.services.datum_gateway;
in {
  options.services.datum_gateway = {
    enable = mkEnableOption "datum_gateway, implements lightweight efficient client side decentralized block template creation for true solo mining.";

    package = mkOption {
      type = types.package;
      description = "The datum_gateway package.";
    };

    instances = mkOption {
      type = types.enum [ "solo" "pool" "both" ];
      default = "both";
      example = "both";
      description = "Which DATUM Gateway instances to enable: 'solo', 'pool', or 'both'.";
    };

    network = mkOption {
      type = types.enum [ "mainnet" "testnet" "regtest" "signet" ];
      default = "mainnet";
      example = "mainnet";
      description = "The bitcoin network the bitcoind node is connected to.";
    };

    logLevel = mkOption {
      type = types.enum [ "all" "debug" "info" " warn" "error" "fatal"];
      default = "info";
      example = "info";
      description = "The logging level.";
    };

    openFirewallPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall TCP ports needed for Stratum.";
    };

    user = mkOption {
      type = types.str;
      default = "datum_gateway";
      description = "The user used to run datum_gateway";
    };

    group = mkOption {
      type = types.str;
      default = "datum_gateway";
      description = "The group used to run datum_gateway";
    };

    dataDirectory = mkOption {
      type = types.path;
      default = "/var/lib/datum_gateway";
      example = "/var/lib/datum_gateway";
      description = "The root path where datum_gateway stores its data.";
    };

    bitcoind = {
      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "127.0.0.1";
        description = "The network IP used by the bitcoind RPC.";
      };

      port = mkOption {
        type = types.port;
        default = 8332;
        description = "The network port used by the bitcoind RPC.";
      };

      workUpdatesDelay = mkOption {
        type = types.numbers.between 5 120;
        default = 40;
        description = "The number of seconds between normal work updates.";
      };

      user = mkOption {
        type = types.str;
        default = "";
        example = "bitcoinmaxi";
        description = "The bitcoind RPC username.";
      };

      passwordFile = mkOption {
        type = types.path;
        example = "/super/secret/location/password.txt";
        description = "The path to a file containing the bitcoind RPC password.";
      };
    };

    api = {
      address = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "127.0.0.1";
        description = "The network IP used by the API/Dashboard.";
      };

      port = mkOption {
        type = types.port;
        default = 7152;
        example = 7152;
        description = "Starting port number used by API/Dashboard. By default, 7152 for solo mining and 7153 for pool mining.";
      };

      adminPasswordFile = mkOption {
        type = types.path;
        example = "/user/secret/location/admin_password.txt";
        description = "The path to a file containing the administrative password for the API/dashboard.";
      };
    };

    stratum = {
      address = mkOption {
        type = types.str;
        default = "0.0.0.0";
        example = "0.0.0.0";
        description = "The network IP used by stratum.";
      };

      port = mkOption {
        type = types.port;
        default = 23334;
        example = 23334;
        description = "Starting port number. By default, 23334 for solo mining and 23335 for pool mining.";
      };

      maxClientsPerThread = mkOption {
        type = types.numbers.positive;
        default = 128;
        example = 128;
        description = "The maximum number of clients per thread.";
      };

      maxThreads = mkOption {
        type = types.numbers.positive;
        default = 8;
        example = 8;
        description = "The maximum number of threads.";
      };

      maxClients = mkOption {
        type = types.numbers.positive;
        default = 1024;
        example = 1024;
        description = "The maximum number of clients.";
      };

      shareStale = mkOption {
        type = types.numbers.positive;
        default = 120;
        example = 120;
        description = "Number of seconds after a job is generated before a share submission is considered stale.";
      };

      fingerprintMiners = mkOption {
        type = types.bool;
        default = true;
        example = true;
        description = "Attempt to fingerprint miners for better use of coinbase space.";
      };

      workDifficulty = {
        minimum = mkOption {
          type = types.numbers.positive;
          default = 16384;
          example = 16384;
          description = "The minimum work difficulty.";
        };

        sharesPerMinute = mkOption {
          type = types.numbers.positive;
          default = 8;
          example = 8;
          description = "Shares per minute.";
        };

        quickDiff = {
          count = mkOption {
            type = types.numbers.positive;
            default = 8;
            example = 8;
            description = "Number of shares before a quick diff update.";
          };

          delta = mkOption {
            type = types.numbers.positive;
            default = 8;
            example = 8;
            description = "How much faster the miner must be before a quick diff.";
          };
        };
      };

      idleTimeout = {
        noSubscribe = mkOption {
          type = types.ints.unsigned;
          default = 15;
          example = 15;
          description = "The number of seconds a connection can be idle without a work subscription. Set to 0 to disable.";
        };

        noShares = mkOption {
          type = types.ints.unsigned;
          default = 7200;
          example = 7200;
          description = "The number of seconds a connection can be idle without accepted shares. Set to 0 to disable.";
        };

        maxLastWork = mkOption {
          type = types.ints.unsigned;
          default = 0;
          example = 0;
          description = "The number of seconds a connection can be idle since its last accepted share. Set to 0 to disable.";
        };
      };
    };

    mining = {
      poolAddress = mkOption {
        type = types.str;
        default = "";
        example = "bc1q1p4fzxxeedmc0d8gp5gq2zjl27rmr8lmz8xp7g";
        description = "The Bitcoin address used for mining rewards.";
      };

      soloMiningTag = mkOption {
        type = types.str;
        default = "DATUM Gateway";
        example = "NixOS Mining";
        description = "The coinbase transaction tag for solo mining.";
      };

      poolMiningTag = mkOption {
        type = types.str;
        default = "DATUM User";
        example = "NixOS Mining";
        description = "The coinbase transaction tag for pool mining.";
      };

      id = mkOption {
        type = types.numbers.between 1 65535;
        default = 4242;
        example = 4242;
        description = "A unique ID appended to the coinbase transaction.";
      };
    };

    datum = {
      pool = {
        port = mkOption {
          type = types.port;
          default = 28915; 
          example = 28915; 
          description = "The remote DATUM server port used for decentralized pool mining.";
        };

        host = mkOption {
          type = types.str;
          default = "datum-beta1.mine.ocean.xyz"; 
          example = "datum-beta1.mine.ocean.xyz"; 
          description = "The remote DATUM server host/IP used for decentralized pool mining.";
        };

        pubKey = mkOption {
          type = types.str;
          default = "f21f2f0ef0aa1970468f22bad9bb7f4535146f8e4a8f646bebc93da3d89b1406f40d032f09a417d94dc068055df654937922d2c89522e3e8f6f0e649de473003"; 
          example = "f21f2f0ef0aa1970468f22bad9bb7f4535146f8e4a8f646bebc93da3d89b1406f40d032f09a417d94dc068055df654937922d2c89522e3e8f6f0e649de473003"; 
          description = "The public key of the remote DATUM server.";
        };
      };

      alwaysPaySelf = mkOption {
        type = types.bool;
        default = true;
        example = true;
        description = "Include my DATUM pool username payout in my blocks when possible.";
      };

      protocolGlobalTimeout = mkOption {
        type = types.numbers.positive;
        default = 60;
        example = 60;
        description = "If no valid messages are received from the DATUM server in this many seconds, give up and try to reconnect.";
      };
    };

    blockNotifyCmd = let
      cmd = port: "${getExe pkgs.curl} -s --out-null http://${cfg.api.address}:${builtins.toString port}/NOTIFY";
      script = pkgs.writeShellScript "datum_gateway_notify.bash" ''
        ${lib.optionalString (cfg.instances == "pool" || cfg.instances == "both") "${cmd (cfg.api.port + 1)}"}
        ${lib.optionalString (cfg.instances == "solo" || cfg.instances == "both") "${cmd cfg.api.port}"}
      '';
    in mkOption {
      type = types.str;
      default = "${script}";
      description = "The command bitcoind should use to notify datum_gateway when the 'best block' has changed. This command needs to be set in bitcoind using the 'blocknotify' option. It's best to leave this unchanged.";
    };
  };

  config = let
    logLevelFromName = name: {
      "all" = 0;
      "debug" = 1;
      "info" = 2;
      "warn" = 3;
      "error" = 4;
      "fatal" = 5;
    }."${name}";

    mkLauncher = instanceName: instanceCfg: let
      desktopItem = pkgs.makeDesktopItem {
        name = "datum_gateway-${instanceName}";
        icon = "datum_gateway";
        type = "Link";
        url = "http://${cfg.api.address}:${builtins.toString instanceCfg.api.port}";
        desktopName = "DATUM Gateway (${instanceName} mining)";
      };
    in pkgs.runCommand "datum_gateway-launcher" {} ''
      mkdir -p $out/share
      ln -s ${desktopItem}/share/applications $out/share/applications
      ln -s ${cfg.package}/share/icons $out/share/icons
    ''; 

    # Which instances to *exclude*.
    disabledInstances = {
      both = [];
      solo = [ "pool" ];
      pool = [ "solo" ];
    }."${cfg.instances}";

    # A data directory is created for each *enabled* instance.
    instances = builtins.removeAttrs {
      solo = rec {
        dataDir = "${cfg.dataDirectory}/${cfg.network}/solo";
        configFile = "${dataDir}/config.json";

        api = {
          port = cfg.api.port;
        };

        datum = {
          pool = { 
            pooledMiningOnly = false;
          };
        };

        stratum = {
          port = cfg.stratum.port;
        };
      };

      pool = rec {
        dataDir = "${cfg.dataDirectory}/${cfg.network}/pool";
        configFile = "${dataDir}/config.json";

        api = {
          port = cfg.api.port + 1;
        };

        datum = {
          pool = { 
            pooledMiningOnly = true;
          };
        };

        stratum = {
          port = cfg.stratum.port + 1;
        };
      };
    } disabledInstances;

    # A data directory is created for each *enabled* instance.
    dataDirs = builtins.mapAttrs
      (instance: instanceCfg: instanceCfg.dataDir) instances;

    # The config file is stored in a directory so that the rpc password
    # can be kept out of the Nix store.
    configFiles = builtins.mapAttrs
      (instance: instanceCfg: instanceCfg.configFile) instances;
    
    # Names the systemd services which will be created. 
    # Etc: { "datum_gateway-solo" = 
    #  { dataDir = "/var/lib/datum_gateway/solo"; 
    #    apiPort = 123;
    #    stratumPort = 456;
    #  };
    # }
    services = builtins.listToAttrs
      (builtins.map
        (instance: { name = "datum_gateway-${instance}"; value = instances."${instance}"; }) (builtins.attrNames instances)
      );

    # The config file is saved into the Nix store as an incomplete template.
    # Namely, the password is declared as a placeholder.
    # This placeholder is then replaced at runtime with the actual password.
    mkConfigFileTemplate = instanceCfg: let
      poolHost = if instanceCfg.datum.pool.pooledMiningOnly then cfg.datum.pool.host else "";
    in pkgs.writeText "datum_gateway_config.json" ''
    {
      "bitcoind": {
        "rpcurl": "${cfg.bitcoind.address}:${builtins.toString cfg.bitcoind.port}",
        "rpcuser": "${cfg.bitcoind.user}",
        "rpcpassword": "7893C4DC45BBC26ABE551E799D284048CA32B207",
        "work_update_seconds": ${builtins.toString cfg.bitcoind.workUpdatesDelay},
        "notify_fallback": false
      },
      "stratum": {
        "listen_address": "${cfg.stratum.address}",
        "listen_port": ${builtins.toString instanceCfg.stratum.port},
        "max_clients_per_thread": ${builtins.toString cfg.stratum.maxClientsPerThread},
        "max_threads": ${builtins.toString cfg.stratum.maxThreads},
        "max_clients": ${builtins.toString cfg.stratum.maxClients},
        "trust_proxy": -1,
        "vardiff_min": ${builtins.toString cfg.stratum.workDifficulty.minimum},
        "vardiff_target_shares_min": ${builtins.toString cfg.stratum.workDifficulty.sharesPerMinute}, 
        "vardiff_quickdiff_count": ${builtins.toString cfg.stratum.workDifficulty.quickDiff.count},
        "vardiff_quickdiff_delta": ${builtins.toString cfg.stratum.workDifficulty.quickDiff.delta},
        "share_stale_seconds": ${builtins.toString cfg.stratum.shareStale},
        "fingerprint_miners": ${if cfg.stratum.fingerprintMiners then "true" else "false"},
        "idle_timeout_no_subscribe": ${builtins.toString cfg.stratum.idleTimeout.noSubscribe}, 
        "idle_timeout_no_shares": ${builtins.toString cfg.stratum.idleTimeout.noShares},
        "idle_timeout_max_last_work": ${builtins.toString cfg.stratum.idleTimeout.maxLastWork}
      },
      "datum": {
        "pool_host": "${poolHost}",
        "pool_port": ${builtins.toString cfg.datum.pool.port},
        "pool_pubkey": "${cfg.datum.pool.pubKey}",
        "pool_pass_workers": ${if instanceCfg.datum.pool.pooledMiningOnly then "true" else "false"},
        "pool_pass_full_users": ${if instanceCfg.datum.pool.pooledMiningOnly then "true" else "false"},
        "always_pay_self": ${if cfg.datum.alwaysPaySelf then "true" else "false"},
        "pooled_mining_only": ${if instanceCfg.datum.pool.pooledMiningOnly then "true" else "false"},
        "protocol_global_timeout": ${builtins.toString cfg.datum.protocolGlobalTimeout}
      },
      "mining": {
        "pool_address": "${cfg.mining.poolAddress}",
        "coinbase_tag_primary": "${cfg.mining.soloMiningTag}",
        "coinbase_tag_secondary": "${cfg.mining.poolMiningTag}",
        "coinbase_unique_id": ${builtins.toString cfg.mining.id}
      },
      "api": {
        "admin_password": "4B7D5382EAD069730165A96FFB67A1FB84DE3194",
        "allow_insecure_auth": false,
        "listen_addr": "${builtins.toString cfg.api.address}",
        "listen_port": ${builtins.toString instanceCfg.api.port},
        "modify_conf": false
      },
      "logger": {
        "log_to_console": true,
        "log_to_stderr": false,
        "log_to_file": false,
        "log_level_console": ${builtins.toString (logLevelFromName cfg.logLevel)}
      }
    }
    '';
  in lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.api.adminPasswordFile == "");
        message = "The API admin password is required.";
      }

      {
        assertion = !(cfg.user == "");
        message = "The datum gateway user is required.";
      }

      {
        assertion = !(cfg.group == "");
        message = "The datum gateway group is required.";
      }

      {
        assertion = !(cfg.bitcoind.user == "");
        message = "The bitcoind RPC user is required.";
      }

      {
        assertion = !(cfg.bitcoind.passwordFile == "");
        message = "The bitcoind RPC password is required.";
      }

      {
        assertion = !(cfg.mining.poolAddress == "");
        message = "The mining pool address is required.";
      }

      {
        assertion = !(cfg.stratum.address == "");
        message = "The stratum IP address is required.";
      }

      {
        assertion = !(cfg.datum.pool.host == "");
        message = "The datum pool host/IP is required.";
      }
    ];

    environment.systemPackages = builtins.attrValues
      (builtins.mapAttrs
        (instance: instanceCfg: mkLauncher instance instanceCfg)
        instances);

    systemd.tmpfiles.rules = builtins.attrValues (builtins.mapAttrs
      (instance: dataDir: "d ${dataDir} 770 ${cfg.user} ${cfg.group} -")
      dataDirs);

    users.users."${cfg.user}" = {
      group = cfg.group;
      description = "Bitcoin DATUM Gateway user";
      isSystemUser = true;
    };

    users.groups."${cfg.group}" = {};

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewallPorts
      (builtins.map
        (instanceCfg: instanceCfg.stratum.port)
        (builtins.attrValues instances));

    systemd.services = builtins.mapAttrs (instance: instanceCfg: {
      requires = [ "bitcoind-${cfg.network}.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = let
        configFile = instanceCfg.configFile;
      in {
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        Restart = "on-failure";
        ReadWritePaths = [ instanceCfg.dataDir ];

        # Take the config file template and substitute the password.
        ExecStartPre = pkgs.writeShellScript "datum_gateway_${instance}_setup.bash" ''
          set -e
          set -o pipefail

          export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.perl ]}"
          export apipass="$(cat ${cfg.bitcoind.passwordFile})"
          export adminpass="$(cat ${cfg.api.adminPasswordFile})"

          cp ${mkConfigFileTemplate instanceCfg} ${configFile}
          chmod u+w ${configFile}
          perl -i -pe 's/7893C4DC45BBC26ABE551E799D284048CA32B207/$ENV{apipass}/g' ${configFile}
          perl -i -pe 's/4B7D5382EAD069730165A96FFB67A1FB84DE3194/$ENV{adminpass}/g' ${configFile}

        '';

        ExecStart = "${getExe cfg.package} -c ${configFile}";
      };
    }) services;
  };

  meta.maintainers = with maintainers; [ emmanuelrosa ];
}
