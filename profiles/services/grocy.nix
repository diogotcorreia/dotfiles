# Configuration for Grocy (https://github.com/grocy/grocy).
# Module inspired by Nixpkgs' https://github.com/NixOS/nixpkgs/blob/nixos-23.05/nixos/modules/services/web-apps/grocy.nix
# but adapted to work with Caddy instead of Nginx.
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) boolToString optionalString;

  domain = "grocy.diogotc.com";

  dataDir = "/var/lib/grocy";
  user = "grocy";
  group = "grocy";
  settings = {
    culture = "en";
    currency = "SEK";
    calendar = {
      firstDayOfWeek = "1";
      showWeekNumber = true;
    };
  };

  grocyConfig = pkgs.writeText "config.php" ''
    <?php
      Setting('CULTURE', '${settings.culture}');
      Setting('CURRENCY', '${settings.currency}');
      Setting('CALENDAR_FIRST_DAY_OF_WEEK', '${
      toString settings.calendar.firstDayOfWeek
    }');
      Setting('CALENDAR_SHOW_WEEK_OF_YEAR', ${
      boolToString settings.calendar.showWeekNumber
    });
  '';
in {
  users.users.${user} = {
    inherit group;
    home = dataDir;
    isSystemUser = true;
  };
  users.groups.${group}.members = [user config.services.caddy.user];

  systemd.tmpfiles.rules =
    map (dirName: "d '${dataDir}${
      optionalString (dirName != null) "/${dirName}"
    }' 0750 ${user} ${group}") [
      null
      "viewcache"
      "plugins"
      "settingoverrides"
      "storage"
    ];

  services.phpfpm.pools.grocy = {
    inherit user group;

    phpPackage = pkgs.php82;

    settings = {
      "pm" = "dynamic";
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "listen.owner" = config.services.caddy.user;
      "listen.group" = config.services.caddy.group;
      "catch_workers_output" = true;
      "pm.max_children" = "32";
      "pm.start_servers" = "2";
      "pm.min_spare_servers" = "2";
      "pm.max_spare_servers" = "4";
      "pm.max_requests" = "500";
    };

    phpEnv = {
      GROCY_CONFIG_FILE = toString grocyConfig;
      GROCY_DB_FILE = "${dataDir}/grocy.db";
      GROCY_STORAGE_DIR = "${dataDir}/storage";
      GROCY_PLUGIN_DIR = "${dataDir}/plugins";
      GROCY_CACHE_DIR = "${dataDir}/viewcache";
    };
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        root * ${pkgs.unstable.grocy}/public
        php_fastcgi unix/${config.services.phpfpm.pools.grocy.socket}
        file_server

        @static_files {
          path_regexp \.(js|css|ttf|woff2?|png|jpe?g|svg)
        }

        header @static_files ?Cache-Control "public, max-age=15778463"
        header @static_files ?X-Content-Type-Options nosniff
        header @static_files ?X-XSS-Protection "1; mode=block"
        header @static_files ?X-Robots-Tag none
        header @static_files ?X-Download-Options noopen
        header @static_files ?X-Permitted-Cross-Domain-Policies none
        header @static_files ?Referrer-Policy no-referrer
      '';
    };
  };

  modules.impermanence.directories = [dataDir];

  modules.services.restic.paths = [dataDir];
}
