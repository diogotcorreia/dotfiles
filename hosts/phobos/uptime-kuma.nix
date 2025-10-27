# Configuration for Uptime Kuma on Phobos
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  domain = "uptime.diogotc.com";
  port = lib.my.ports.uptimeKuma;

  stateDir = lib.my.toPrivateStateDirectory "/var/lib/uptime-kuma";
in
{
  disabledModules = [
    "services/monitoring/uptime-kuma.nix"
  ];
  imports = [
    (inputs.nixpkgs-uptime-kuma-pr + "/nixos/modules/services/monitoring/uptime-kuma.nix")
  ];

  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "::1";
      PORT = toString port;
    };
    package = pkgs.uptime-kuma-2; # TODO 25.11: use stable
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };

  modules.services.restic.paths = [ stateDir ];
  modules.impermanence.directories = [ stateDir ];
}
