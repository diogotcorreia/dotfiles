# Configuration for Healthchecks.io on Phobos
{
  pkgs,
  config,
  secrets,
  ...
}: let
  httpHost = "http.${host}";
  host = "healthchecks.diogotc.com";
  port = 8003;
  dbUser = config.services.healthchecks.user;
  commonSecretSettings = {
    owner = config.services.healthchecks.user;
    group = config.services.healthchecks.group;
  };
in {
  age.secrets = {
    phobosHealthchecksSecretKey =
      commonSecretSettings
      // {
        file = secrets.host.healthchecksSecretKey;
      };
    phobosHealthchecksEnvVariables = {
      file = secrets.host.healthchecksEnvVariables;
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [dbUser];
  };

  services.healthchecks = {
    inherit port;
    enable = true;
    package = pkgs.healthchecks;

    # Pass non-secret settings
    settings = {
      ALLOWED_HOSTS = [host httpHost];
      APPRISE_ENABLED = "False";

      # Database configuration (using peer authentication; no password needed)
      DB = "postgres";
      DB_HOST = "";
      DB_NAME = dbUser;
      DB_USER = dbUser;

      # WebAuthn domain
      RP_ID = host;

      DEFAULT_FROM_EMAIL = "healthchecks@diogotc.com";
      # EMAIL_HOST, EMAIL_HOST_USER, EMAIL_HOST_PASSWORD are defined as secrets
      SECRET_KEY_FILE = config.age.secrets.phobosHealthchecksSecretKey.path;

      PING_BODY_LIMIT = "10000";
      PING_EMAIL_DOMAIN = "diogotc.com";
      PING_ENDPOINT = "https://${host}/ping/";

      SITE_NAME = "Healthchecks DTC";
      SITE_ROOT = "https://${host}";

      # TELEGRAM_BOT_NAME, TELEGRAM_TOKEN_FILE are defined as secrets

      TZ = "UTC";
    };
  };

  systemd.services = let
    commonConfig = {
      serviceConfig = {
        EnvironmentFile = [config.age.secrets.phobosHealthchecksEnvVariables.path];
      };
    };
  in {
    healthchecks-migration = commonConfig;
    healthchecks = commonConfig;
    healthchecks-sendalerts = commonConfig;
    healthchecks-sendreports = commonConfig;
  };

  services.caddy.virtualHosts = {
    ${host} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
      '';
    };
    # http-only route, used to receive pings from iot devices that can't use https
    "http://${httpHost}" = {
      extraConfig = ''
        handle /ping/* {
          reverse_proxy localhost:${toString port}
        }
        handle {
          redir https://${host}{uri}
        }
      '';
    };
  };

  modules.services.restic.paths = [config.services.healthchecks.dataDir];
}
