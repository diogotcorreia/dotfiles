# Configuration for Paperless-ngx on Hera
{
  pkgs,
  config,
  hostSecretsDir,
  ...
}: let
  domain = "paperless.diogotc.com";
  port = config.services.paperless.port;

  dataDir = config.services.paperless.dataDir;

  dbUser = config.services.paperless.user;
in {
  age.secrets.heraPaperlessEnvVariables = {
    file = "${hostSecretsDir}/paperlessEnvVariables.age";
    owner = config.services.paperless.user;
    group = config.services.paperless.user;
  };

  services.paperless = {
    enable = true;

    extraConfig = {
      PAPERLESS_OCR_LANGUAGE = "eng+por+swe";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };

      PAPERLESS_URL = "https://${domain}";
    };
  };

  # Seems like there isn't a great way to set the PAPERLESS_SECRET_KEY env variable?
  # We add it to all services then:
  systemd.services = let
    commonConfig = {
      serviceConfig = {
        # has PAPERLESS_SECRET_KEY
        EnvironmentFile = [config.age.secrets.heraPaperlessEnvVariables.path];
      };
    };
  in {
    paperless-scheduler = commonConfig;
    paperless-task-queue = commonConfig;
    paperless-consumer = commonConfig;
    paperless-web = commonConfig;
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

  security.acme.certs.${domain} = {};

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  modules.impermanence.directories = [dataDir];

  modules.services.restic.paths = [dataDir];
}
