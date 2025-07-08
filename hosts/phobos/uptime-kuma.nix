# Configuration for Uptime Kuma on Phobos
{
  lib,
  pkgs,
  ...
}: let
  domain = "uptime.diogotc.com";
  port = lib.my.ports.uptimeKuma;

  stateDir = lib.my.toPrivateStateDirectory "/var/lib/uptime-kuma";
in {
  services.uptime-kuma = {
    enable = true;
    settings = {PORT = toString port;};
    package = pkgs.unstable.uptime-kuma;
  };

  services.caddy.virtualHosts.${domain} = {
    enableACME = true;
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

  modules.services.restic.paths = [stateDir];
  modules.impermanence.directories = [stateDir];
}
