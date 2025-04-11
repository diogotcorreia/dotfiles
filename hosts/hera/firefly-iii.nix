# Configuration for Firefly-III on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  domainApp = "firefly3.hera.diogotc.com";
  domainDataImporter = "firefly3-csv.hera.diogotc.com";

  cronAutoDataImporter = "07:00";
  configPathAutoDataImporter = "/persist/firefly-auto-import-configs";

  dbUser = config.services.firefly-iii.user;
in {
  age.secrets = {
    fireflyAppKey = {
      owner = config.services.firefly-iii.user;
      file = secrets.host.fireflyAppKey;
    };
    fireflyAutoDataImporterEnv.file = secrets.host.fireflyAutoDataImporterEnv;
    fireflyAutoDataImporterHealthchecksUrl = {
      owner = config.services.firefly-iii-data-importer.user;
      file = secrets.host.fireflyAutoDataImporterHealthchecksUrl;
    };
    fireflyDataImporterEnv.file = secrets.host.fireflyDataImporterEnv;
  };

  services.firefly-iii = {
    enable = true;
    package = pkgs.firefly-iii;
    virtualHost = domainApp;
    enableNginx = true;
    settings = {
      APP_ENV = "production";
      APP_KEY_FILE = config.age.secrets.fireflyAppKey.path;
      SITE_OWNER = "firefly-iii.${config.networking.hostName}@diogotc.com";
      DB_CONNECTION = "pgsql";
    };
  };

  services.firefly-iii-data-importer = {
    enable = true;
    package = pkgs.firefly-iii-data-importer;
    virtualHost = domainDataImporter;
    enableNginx = true;
    settings = {
      FIREFLY_III_URL = "https://${domainApp}";
      FIREFLY_III_CLIENT_ID = 7;
      JSON_CONFIGURATION_DIR = configPathAutoDataImporter;
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    ensureDatabases = [dbUser];
  };

  # The data-importer module does not allow for variables to be passed in bulk, so we do this little hack
  systemd.services.firefly-iii-data-importer-setup.serviceConfig.EnvironmentFile = [
    # Contains variables:
    # - NORDIGEN_ID
    # - NORDIGEN_KEY
    config.age.secrets.fireflyDataImporterEnv.path
  ];

  systemd.services.firefly-iii-auto-importer = {
    environment = {
      FIREFLY_III_URL = "https://${domainApp}";
      IMPORT_DIR_ALLOWLIST = configPathAutoDataImporter;
      ENABLE_MAIL_REPORT = "true";

      # Don't show warnings about duplicate (already imported) transactions
      IGNORE_DUPLICATE_ERRORS = "true";
      # Don't show warnings about transactions immediately deleted by a rule
      IGNORE_NOT_FOUND_TRANSACTIONS = "true";

      # Email configuration
      MAIL_DESTINATION = lib.my.mkDtcEmail "firefly-iii";
      MAIL_MAILER = "smtp";
      MAIL_HOST = "mail.diogotc.com";
      MAIL_PORT = "465";
      MAIL_ENCRYPTION = "tls";
      MAIL_USERNAME = lib.my.mkRobotsEmail "firefly-iii";
      MAIL_FROM_ADDRESS = lib.my.mkRobotsEmail "firefly-iii";
    };
    # Inherit the config from the data importer
    serviceConfig = let
      stateDir = "firefly-iii-auto-importer";
      dataImporterPackage = pkgs.firefly-iii-data-importer.override (prev: {
        dataDir = "/var/lib/${stateDir}";
      });
      artisan = "${dataImporterPackage}/artisan";
    in
      config.systemd.services.firefly-iii-data-importer-setup.serviceConfig
      // {
        Type = "oneshot";
        RemainAfterExit = false;
        StateDirectory = stateDir;
        ExecStart = pkgs.writeShellScript "firefly-iii-auto-importer-script" ''
          ${artisan} package:discover
          ${artisan} cache:clear
          ${artisan} config:cache
          ${artisan} importer:auto-import ${lib.escapeShellArg configPathAutoDataImporter}
        '';
        EnvironmentFile = [
          # Contains variables:
          # - NORDIGEN_ID
          # - NORDIGEN_KEY
          config.age.secrets.fireflyDataImporterEnv.path
          # Contains variables:
          # - FIREFLY_III_ACCESS_TOKEN
          # - MAIL_PASSWORD
          config.age.secrets.fireflyAutoDataImporterEnv.path
        ];
      };
  };

  # https://github.com/NixOS/nixpkgs/blob/a3c0b3b21515f74fd2665903d4ce6bc4dc81c77c/nixos/modules/services/web-apps/firefly-iii-data-importer.nix#L254-L287
  systemd.tmpfiles.settings."10-firefly-iii-auto-importer" = let
    dataDir = "/var/lib/${config.systemd.services.firefly-iii-auto-importer.serviceConfig.StateDirectory}";
    inherit (config.services.firefly-iii-data-importer) user group;
  in
    lib.attrsets.genAttrs
    [
      "${dataDir}/storage"
      "${dataDir}/storage/app"
      "${dataDir}/storage/app/public"
      "${dataDir}/storage/configurations"
      "${dataDir}/storage/conversion-routines"
      "${dataDir}/storage/debugbar"
      "${dataDir}/storage/framework"
      "${dataDir}/storage/framework/cache"
      "${dataDir}/storage/framework/sessions"
      "${dataDir}/storage/framework/testing"
      "${dataDir}/storage/framework/views"
      "${dataDir}/storage/jobs"
      "${dataDir}/storage/logs"
      "${dataDir}/storage/submission-routines"
      "${dataDir}/storage/uploads"
      "${dataDir}/cache"
    ]
    (n: {
      d = {
        group = group;
        mode = "0710";
        user = user;
      };
    })
    // {
      "${dataDir}".d = {
        group = group;
        mode = "0700";
        user = user;
      };
    };

  # Schedule Firefly Auto Importer
  systemd.timers.firefly-iii-auto-importer = {
    wantedBy = ["timers.target"];
    timerConfig = {OnCalendar = cronAutoDataImporter;};
  };

  # Healthchecks for Firefly Auto Importer
  modules.services.healthchecks.systemd-monitoring.firefly-iii-auto-importer = {
    checkUrlFile = config.age.secrets.fireflyAutoDataImporterHealthchecksUrl.path;
  };

  services.nginx.virtualHosts = {
    ${domainApp} = {
      enableACME = true;
      restrictToNebula = true;
    };
    ${domainDataImporter} = {
      enableACME = true;
      restrictToNebula = true;
    };
  };

  modules.impermanence.directories = [
    config.services.firefly-iii.dataDir
    config.services.firefly-iii-data-importer.dataDir
  ];

  modules.services.restic.paths = [
    "${config.services.firefly-iii.dataDir}/storage/upload"
    configPathAutoDataImporter
  ];
}
