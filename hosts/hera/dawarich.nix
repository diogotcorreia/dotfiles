# Configuration for Dawarich (Location Timeline) on Hera
{
  config,
  lib,
  pkgs,
  ...
}: let
  domain = "location.diogotc.com";
  port = 3000;
in {
  # TODO move docker containers to NixOS services

  services.caddy.virtualHosts.${domain} = {
    enableACME = true;
    extraConfig = ''
      # Require auth for everything except upload and health endpoints
      # App is in development mode, so better not trust it
      @require_auth {
        not {
          method POST
          path /api/v1/owntracks/points
        }
        not {
          method GET
          path /api/v1/health
        }
      }
      handle @require_auth {
        import AUTHELIA
        reverse_proxy localhost:${toString port}
      }

      handle {
        reverse_proxy localhost:${toString port}
      }
    '';
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
}
