{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domain = "grimoire.diogotc.com";

  user = "pocket-grimoire";
  group = "pocket-grimoire";

  dataDir = "/var/lib/pocket-grimoire";
  package = pkgs.my.pocket-grimoire;

  env = {
    APP_ENV = "prod";
    APP_SECRET_FILE = config.age.secrets.pocketGrimoireAppSecret.path;

    DATABASE_URL = "postgresql://${user}@localhost/${user}?host=/run/postgresql";
  };

  commonServiceConfig = {
    Type = "oneshot";
    User = user;
    Group = group;
    StateDirectory = "pocket-grimoire";
    CacheDirectory = "pocket-grimoire";
    LogsDirectory = "pocket-grimoire";
    ReadWritePaths = [ dataDir ];
    WorkingDirectory = package;
    PrivateTmp = true;
    PrivateDevices = true;
    CapabilityBoundingSet = "";
    AmbientCapabilities = "";
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectHome = "tmpfs";
    ProtectKernelLogs = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    PrivateNetwork = false;
    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service @resources"
      "~@obsolete @privileged"
    ];
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    NoNewPrivileges = true;
    RestrictRealtime = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    PrivateUsers = true;
  };
in
{
  age.secrets = {
    pocketGrimoireAppSecret = {
      owner = user;
      file = secrets.host.pocketGrimoireAppSecret;
    };
  };

  services.phpfpm.pools.pocket-grimoire = {
    inherit user group;
    phpPackage = package.phpPackage;
    phpOptions = ''
      log_errors = on
    '';
    settings = {
      "listen.mode" = lib.mkDefault "0660";
      "listen.owner" = lib.mkDefault config.services.nginx.user;
      "listen.group" = lib.mkDefault config.services.nginx.group;
      "pm" = lib.mkDefault "dynamic";
      "pm.max_children" = lib.mkDefault 32;
      "pm.start_servers" = lib.mkDefault 2;
      "pm.min_spare_servers" = lib.mkDefault 2;
      "pm.max_spare_servers" = lib.mkDefault 4;
      "pm.max_requests" = lib.mkDefault 500;
    };
    phpEnv = {
      inherit (env) APP_ENV APP_SECRET_FILE;
      # FIXME: submit fix upstream to escape phpEnv variables
      DATABASE_URL = "'${env.DATABASE_URL}'";
    };
  };

  systemd.services.pocket-grimoire-setup = {
    after = [
      "postgresql.target"
    ];
    requiredBy = [ "phpfpm-pocket-grimoire.service" ];
    before = [ "phpfpm-pocket-grimoire.service" ];
    script = ''
      rm -rf ${package}/var/cache/*
      ${package}/bin/console doctrine:migrations:migrate
      ${package}/bin/console pocket-grimoire:populate-editions -f ${package}/assets/data/editions.json
      ${package}/bin/console pocket-grimoire:populate-teams -f ${package}/assets/data/teams.json
      ${package}/bin/console pocket-grimoire:populate-roles -f ${package}/assets/data/characters.json
      ${package}/bin/console pocket-grimoire:import
    '';
    serviceConfig = {
      RemainAfterExit = true;
    }
    // commonServiceConfig;
    environment = env;
    unitConfig.JoinsNamespaceOf = "phpfpm-firefly-iii.service";
    restartTriggers = [ package ];
    partOf = [ "phpfpm-pocket-grimoire.service" ];
  };

  services.nginx = {
    enable = lib.mkDefault true;
    virtualHosts.${domain} = {
      enableACME = true;
      root = "${package}/public";
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.php?$query_string";
          index = "index.php";
          extraConfig = ''
            sendfile off;
          '';
        };
        "~ \\.php$" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/fastcgi_params ;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_param modHeadersAvailable true; #Avoid sending the security headers twice
            fastcgi_pass unix:${config.services.phpfpm.pools.pocket-grimoire.socket};
          '';
        };
      };
    };
  };

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    ensureDatabases = [ user ];
  };

  users = {
    users.${user} = {
      description = "pocket-grimoire service user";
      inherit group;
      isSystemUser = true;
      home = dataDir;
    };
    groups.${group} = { };
  };
}
