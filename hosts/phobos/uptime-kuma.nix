# Configuration for Uptime Kuma on Phobos
{
  lib,
  ...
}:
let
  domain = "uptime.diogotc.com";
  port = lib.my.ports.uptimeKuma;

  stateDir = lib.my.toPrivateStateDirectory "/var/lib/uptime-kuma";
in
{
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "::1";
      PORT = toString port;
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };

  modules.services.restic.paths = [ stateDir ];
  modules.impermanence.directories = [ stateDir ];
}
