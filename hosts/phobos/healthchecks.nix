# Configuration for Healthchecks.io on Phobos
args @ {
  pkgs,
  inputs,
  config,
  secrets,
  buildEnv, # unused, but has to be here because of the import of nixpkgs healthchecks module
  ...
}: let
  host = "healthchecks.diogotc.com";
  port = 8003;
  dbUser = config.services.healthchecks.user;
  commonSecretSettings = {
    owner = config.services.healthchecks.user;
    group = config.services.healthchecks.group;
  };
in {
  # Import unstable module, since it uses some python dependencies directly
  # https://stackoverflow.com/questions/47650857/nixos-module-imports-with-arguments
  disabledModules = ["services/web-apps/healthchecks.nix"];
  imports = [
    (import (inputs.nixpkgs-unstable
      + "/nixos/modules/services/web-apps/healthchecks.nix")
    (args // {pkgs = pkgs.unstable;}))
  ];

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
    package = pkgs.unstable.healthchecks;

    # Pass non-secret settings
    settings = {
      ALLOWED_HOSTS = [host];
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

  services.caddy.virtualHosts.${host} = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

  modules.services.restic.paths = [config.services.healthchecks.dataDir];
}
