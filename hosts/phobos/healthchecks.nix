# Configuration for Healthchecks.io on Phobos
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  httpHost = "http.${host}";
  host = "healthchecks.diogotc.com";
  port = lib.my.ports.healthchecks;
  dbUser = config.services.healthchecks.user;
  commonSecretSettings = {
    owner = config.services.healthchecks.user;
    group = config.services.healthchecks.group;
  };
in
{
  age.secrets = {
    phobosHealthchecksSecretKey = commonSecretSettings // {
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
    ensureDatabases = [ dbUser ];
  };

  services.healthchecks = {
    inherit port;
    listenAddress = "[::1]";
    enable = true;
    package = pkgs.healthchecks;

    # Pass non-secret settings
    settings = {
      ALLOWED_HOSTS = [
        host
        httpHost
      ];
      APPRISE_ENABLED = "False";

      # Database configuration (using peer authentication; no password needed)
      DB = "postgres";
      DB_HOST = "";
      DB_NAME = dbUser;
      DB_USER = dbUser;

      # WebAuthn domain
      RP_ID = host;

      DEFAULT_FROM_EMAIL = lib.my.mkRobotsEmail "healthchecks";
      EMAIL_HOST = "mail.diogotc.com";
      EMAIL_HOST_USER = lib.my.mkRobotsEmail "healthchecks";
      EMAIL_PORT = "465";
      EMAIL_USE_TLS = "False";
      EMAIL_USE_SSL = "True";
      # EMAIL_HOST_PASSWORD is defined as secret
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

  systemd.services =
    let
      commonConfig = {
        serviceConfig = {
          EnvironmentFile = [ config.age.secrets.phobosHealthchecksEnvVariables.path ];
        };
      };
    in
    {
      healthchecks-migration = commonConfig;
      healthchecks = commonConfig;
      healthchecks-sendalerts = commonConfig;
      healthchecks-sendreports = commonConfig;
    };

  services.nginx.virtualHosts = {
    ${host} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
    # http-only route, used to receive pings from iot devices that can't use https
    ${httpHost} = {
      locations."/ping/".proxyPass = "http://[::1]:${toString port}";
      locations."/".return = "301 https://${host}$request_uri";
    };
  };

  modules.impermanence.directories = [ config.services.healthchecks.dataDir ];
}
