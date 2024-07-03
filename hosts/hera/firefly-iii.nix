# Configuration for Firefly-III on Hera
{
  pkgs,
  config,
  secrets,
  lib,
  ...
}: let
  domainApp = "firefly3.hera.diogotc.com";
  portApp = 8005;
  domainDataImporter = "firefly3-csv.hera.diogotc.com";
  portDataImporter = 8006;
  versionDataImporter = "1.4.2";

  cronAutoDataImporter = "23:58";
  configPathAutoDataImporter = "/persist/firefly-auto-import-configs";

  mkServiceName = container: "${config.virtualisation.oci-containers.backend}-${container}";
in {
  # TODO move docker containers to NixOS services

  age.secrets = {
    fireflyAutoDataImporterEnv.file = secrets.host.fireflyAutoDataImporterEnv;
    fireflyAutoDataImporterHealthchecksUrl.file = secrets.host.fireflyAutoDataImporterHealthchecksUrl;
    fireflyDataImporterEnv.file = secrets.host.fireflyDataImporterEnv;
  };

  virtualisation.oci-containers.containers = {
    # Auto Importer task
    firefly-auto-importer = {
      autoStart = false;
      image = "fireflyiii/data-importer:version-${versionDataImporter}";
      volumes = ["${configPathAutoDataImporter}:/import"];
      environment = {
        FIREFLY_III_URL = "https://${domainApp}";
        IMPORT_DIR_ALLOWLIST = "/import";
        WEB_SERVER = "false";
        ENABLE_MAIL_REPORT = "true";
        TZ = "Europe/Lisbon";
      };
      environmentFiles = [
        # Contains variables:
        # - NORDIGEN_ID
        # - NORDIGEN_KEY
        config.age.secrets.fireflyDataImporterEnv.path
        # Contains variables:
        # - FIREFLY_III_ACCESS_TOKEN
        # - MAIL_DESTINATION
        # - MAIL_MAILER
        # - MAIL_HOST
        # - MAIL_PORT
        # - MAIL_ENCRYPTION
        # - MAIL_USERNAME
        # - MAIL_PASSWORD
        # - MAIL_FROM_ADDRESS
        config.age.secrets.fireflyAutoDataImporterEnv.path
      ];
    };
  };
  systemd.services.${mkServiceName "firefly-auto-importer"} = {
    # Avoid loop, since container is one-shot
    serviceConfig.Restart = lib.mkForce "no";
  };

  # Schedule Firefly Auto Importer
  systemd.timers.${mkServiceName "firefly-auto-importer"} = {
    wantedBy = ["timers.target"];
    timerConfig = {OnCalendar = cronAutoDataImporter;};
  };

  # Healthchecks for Firefly Auto Importer
  modules.services.healthchecks.systemd-monitoring.${
    mkServiceName "firefly-auto-importer"
  }.checkUrlFile =
    config.age.secrets.fireflyAutoDataImporterHealthchecksUrl.path;

  security.acme.certs = {
    ${domainApp} = {};
    ${domainDataImporter} = {};
  };

  services.caddy.virtualHosts = {
    ${domainApp} = {
      useACMEHost = domainApp;
      extraConfig = ''
        import NEBULA
        reverse_proxy localhost:${toString portApp}
      '';
    };
    ${domainDataImporter} = {
      useACMEHost = domainDataImporter;
      extraConfig = ''
        import NEBULA
        reverse_proxy localhost:${toString portDataImporter}
      '';
    };
  };

  modules.services.restic = {
    paths = [
      "/tmp/firefly_db.sql"
      "${config.my.homeDirectory}/firefly-3"
      configPathAutoDataImporter
    ];

    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/firefly_db.sql
      ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/firefly-3/docker-compose.yml exec -T fireflyiiidb sh -c 'exec mysqldump --host=fireflyiiidb --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE' > /tmp/firefly_db.sql
    '';
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm /tmp/firefly_db.sql
    '';
  };
}
