# Configuration for Nextcloud on Hera
{
  pkgs,
  config,
  secrets,
  ...
}: let
  domain = "cloud.diogotc.com";

  dbUsername = "nextcloud";
  dbDatabaseName = "nextcloud";
in {
  age.secrets.nextcloudSecrets = {
    file = secrets.host.nextcloudSecrets;
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = domain;
    database.createLocally = true; # automatically uses pgsql through sockets
    configureRedis = true;
    maxUploadSize = "2G";
    config = {
      adminpassFile =
        toString (pkgs.writeText "nc-first-install-pwd"
          "changeMeAfterFirstInstallPlease");
      dbtype = "pgsql";
      dbuser = dbUsername;
      dbname = dbDatabaseName;
    };
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
      "opcache.revalidate_freq" = "5";
      "opcache.jit" = "1255";
      "opcache.jit_buffer_size" = "128M";
    };
    settings = {
      trusted_proxies = ["127.0.0.1" "::1"];
      overwriteprotocol = "https";

      default_phone_region = "PT";

      "overwrite.cli.url" = "https://${domain}/";
      "upgrade.disable-web" = true;
      maintenance_window_start = 2;
    };
    # Has:
    # mail_from_address
    # mail_smtpmode
    # mail_sendmailmode
    # mail_domain
    # mail_smtpauthtype
    # mail_smtpauth
    # mail_smtphost
    # mail_smtpport
    # mail_smtpsecure
    # mail_smtpname
    # mail_smtppassword
    # instanceid
    # passwordsalt
    # secret
    secretFile = config.age.secrets.nextcloudSecrets.path;
  };
  # Use caddy instead of nginx
  services.phpfpm.pools.nextcloud.settings = {
    "listen.owner" = config.services.caddy.user;
    "listen.group" = config.services.caddy.group;
  };
  users.groups.nextcloud.members = [config.services.caddy.user];

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        encode zstd gzip
        root * ${config.services.nextcloud.package}
        php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
          import CLOUDFLARE_PROXY
          env front_controller_active true # remove index.php from urls
        }
        handle /store-apps/* {
          root * ${config.services.nextcloud.home}
        }
        handle /nix-apps/* {
          root * ${config.services.nextcloud.home}
        }
        redir /.well-known/caldav /remote.php/dav 301
        redir /.well-known/carddav /remote.php/dav 301
        redir /.well-known/* /index.php{uri} 301 # Nextcloud front-controller handles routes to /.well-known
        redir /remote/* /remote.php{uri} 301

        # Required for legacy
        @notlegacy {
          path *.php
          not path /index*
          not path /remote*
          not path /public*
          not path /cron*
          not path /core/ajax/update*
          not path /status*
          not path /ocs/v1*
          not path /ocs/v2*
          not path /updater/*
          not path /ocs-provider/*
          not path */richdocumentscode/proxy*
        }
        rewrite @notlegacy /index.php{uri}

        # Deny access to sensible files and directories
        @forbidden {
          path /build/* /tests/* /config/* /lib/* /3rdparty/* /templates/* /data/*
          path /.* /autotest* /occ* /issue* /indie* /db_* /console*
          not path /.well-known/*
        }
        error @forbidden 404

        # Set cache for versioned static files (cache-busting)
        @immutable {
          path *.css *.js *.mjs *.svg *.gif *.ico *.jpg *.png *.webp *.wasm *.tflite *.map *.ogg *.flac
          query v=*
        }
        header @immutable Cache-Control "max-age=15778463, immutable"

        # Set cache for normal static files
        @static {
          path *.css *.js *.mjs *.svg *.gif *.ico *.jpg *.png *.webp *.wasm *.tflite *.map *.ogg *.flac
          not query v=*
        }
        header @static Cache-Control "max-age=15778463"

        # Cache fonts for 1 week
        @woff2 path *.woff2
        header @woff2 Cache-Control "max-age=604800"

        header ?X-Content-Type-Options nosniff;
        header ?X-XSS-Protection "1; mode=block"
        header ?X-Robots-Tag "noindex, nofollow"
        header ?X-Download-Options noopen
        header ?X-Permitted-Cross-Domain-Policies none
        header ?X-Frame-Options sameorigin
        header ?Referrer-Policy no-referrer
        header ?Strict-Transport-Security "max-age=15768000;"
        header ?Permissions-Policy interest-cohort=()
        header -X-Powered-By

        file_server

        request_body {
          max_size 2GB
        }
      '';
    };
  };

  # Pin nextcloud user's UID and GID, otherwise files may change owner
  users.users.nextcloud.uid = 900;
  users.groups.nextcloud.gid = 900;

  modules.impermanence.directories = [config.services.nextcloud.home];
  modules.services.restic.paths = [config.services.nextcloud.home];
}
