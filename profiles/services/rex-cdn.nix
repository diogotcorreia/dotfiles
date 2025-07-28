# File serve only
{ config, ... }:
let
  dir = "/var/lib/rex-cdn";
in
{
  services.nginx.virtualHosts = {
    "cdn.rexcantor64.com" = {
      enableACME = true;
      enableCloudflareRealIp = true;
      root = dir;
    };
  };

  modules.impermanence.directories = [
    {
      directory = dir;
      group = config.services.nginx.group;
    }
  ];

  modules.services.restic.paths = [ dir ];
}
