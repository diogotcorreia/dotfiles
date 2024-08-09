# Configuration for Book Metadata API on Hera
{pkgs, ...}: let
  domain = "book-api.diogotc.com";
  port = 8004;

  user = "book-metadata-api";
  group = "book-metadata-api";

  stateDirectory = "/var/lib/book-metadata-api";
in {
  users.users.${user} = {
    inherit group;
    isSystemUser = true;
  };
  users.groups.${group} = {};

  systemd.services.book-metadata-api = {
    description = "Book Metadata API";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    # TODO harden systemd unit
    serviceConfig = rec {
      Type = "simple";
      User = user;
      Group = group;
      StateDirectory = "book-metadata-api";
      StateDirectoryMode = "0700";
      CacheDirectory = "book-metadata-api";
      CacheDirectoryMode = "0700";
      UMask = "0077";
      WorkingDirectory = stateDirectory;
      ExecStart = "${pkgs.my.book-metadata-api}/bin/book-metadata-api";
      # chromium needs XDG_CONFIG_HOME to exist and be writable
      Environment = "PORT=${toString port} XDG_CONFIG_HOME=/var/cache/${CacheDirectory}";
      Restart = "on-failure";
      TimeoutSec = 15;
    };
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

  modules.impermanence.files = ["${stateDirectory}/cookies.json"];
}
