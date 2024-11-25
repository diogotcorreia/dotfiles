# Meilisearch configuration
{
  config,
  lib,
  secrets,
  ...
}: let
  dataDir = "/var/lib/meilisearch";
  port = 3449;

  domain = "meilisearch.diogotc.com";

  user = "meilisearch";
  group = "meilisearch";
in {
  age.secrets = {
    meilisearchEnv.file = secrets.host.meilisearchEnv;
  };

  services.meilisearch = {
    enable = true;
    listenPort = port;
    environment = "production";
    # Contains:
    # - MEILI_MASTER_KEY
    masterKeyEnvironmentFile = config.age.secrets.meilisearchEnv.path;
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  users = {
    groups.${group} = {};
    users.${user} = {
      isSystemUser = true;
      inherit group;
    };
  };

  systemd.services.meilisearch = {
    serviceConfig = {
      # Don't use dynamic user since it doesn't work correctly with impermanence
      User = user;
      Group = group;
      DynamicUser = lib.mkForce false;
    };
  };

  modules.impermanence.directories = [dataDir];
  modules.services.restic.paths = [dataDir];
}
