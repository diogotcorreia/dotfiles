# hosts/phobos/atticd.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for atticd (Nix Binary Cache) on Phobos

args@{ pkgs, inputs, config, hostSecretsDir, buildEnv, ... }:
let
  host = "nix-cache.diogotc.com";
  port = 8004;
  dbUser = config.services.atticd.user;
in {

  age.secrets = {
    phobosAtticdEnvVariables = {
      # Contains the following variables:
      # - ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64
      file = "${hostSecretsDir}/atticdEnvVariables.age";
    };
  };

  services.postgresql = {
    ensureUsers = [{
      name = dbUser;
      ensureDBOwnership = true;
    }];
    ensureDatabases = [ dbUser ];
  };

  services.atticd = {
    enable = true;
    mode = "monolithic";
    credentialsFile = config.age.secrets.phobosAtticdEnvVariables.path;
    settings = {
      listen = "[::]:${toString port}";
      allowed-hosts = [ host ];
      api-endpoint = "https://${host}/";
      soft-delete-caches = false;
      require-proof-of-possession = true;

      database.url = "postgresql:///${dbUser}";

      chunking = {
        nar-size-threshold = 65536; # chunk files that are 64 KiB or larger
        min-size = 16384; # 16 KiB
        avg-size = 65536; # 64 KiB
        max-size = 262144; # 256 KiB
      };

      compression = { type = "zstd"; };

      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "7 days";
      };
    };
  };

  # The service above is supposed to detect this based on the database string,
  # but since we're using the shorthand, it doesn't.
  systemd.services.atticd.after = [ "postgresql.service" "nss-lookup.target" ];

  services.caddy.virtualHosts.${host} = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

}
