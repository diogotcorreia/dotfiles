# Meilisearch configuration
{
  config,
  lib,
  secrets,
  ...
}:
let
  dataDir = "/var/lib/meilisearch";
  port = lib.my.ports.meilisearch;

  domain = "meilisearch.diogotc.com";

  user = "meilisearch";
  group = "meilisearch";
in
{
  age.secrets = {
    meilisearchMasterKey.file = secrets.host.meilisearchMasterKey;
  };

  services.meilisearch = {
    enable = true;
    listenAddress = "[::1]";
    listenPort = port;
    settings = {
      env = "production";
      experimental_dumpless_upgrade = true;
    };
    masterKeyFile = config.age.secrets.meilisearchMasterKey.path;
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  users = {
    groups.${group} = { };
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

  modules.impermanence.directories = [ dataDir ];
  modules.services.restic.paths = [ dataDir ];
}
