# Configuration for Dawarich (Location Timeline) on Hera
{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "location.diogotc.com";
  port = lib.my.ports.dawarich;
in {
  # TODO move docker containers to NixOS services

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    autheliaRules = "group:location";
    # Require auth for everything except upload and health endpoints
    # App is in development mode, so better not trust it
    locations = let
      proxyPass = "http://127.0.0.1:${toString port}";
    in {
      "/" = {
        enableAuthelia = true;
        inherit proxyPass;
      };
      "= /api/v1/owntracks/points" = {
        inherit proxyPass;
        extraConfig = ''
          limit_except POST {
            deny all;
          }
        '';
      };
      "= /api/v1/health" = {
        inherit proxyPass;
        extraConfig = ''
          limit_except GET {
            deny all;
          }
        '';
      };
    };
  };

  modules.services.restic = {
    paths = [
      "/tmp/dawarich_db.sql.zstd"
      "${config.my.homeDirectory}/dawarich"
    ];

    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/dawarich_db.sql.zstd
      ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/dawarich/docker-compose.yml exec -T dawarich_db sh -c 'exec pg_dump --format=custom --username=$POSTGRES_USER dawarich_development' | ${lib.getExe' pkgs.zstd "zstd"} -c --adapt > /tmp/dawarich_db.sql.zstd
    '';
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm /tmp/dawarich_db.sql.zstd
    '';
  };

  # TODO: remove when dawarich is migrated to a NixOS module.
  # Required for dumping the database inside the docker container
  systemd.services."restic-backups-systemBackup".serviceConfig.SupplementaryGroups = ["docker"];
}
