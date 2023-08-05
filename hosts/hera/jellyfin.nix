# hosts/hera/jellyfin.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Jellyfin on Hera

{ pkgs, config, ... }:
let
  domain = "jellyfin.diogotc.com";
  port = 8096;
in {

  # TODO setup hardware acceleration

  services.jellyfin.enable = true;

  # Open Jellyfin local discovery ports
  # https://jellyfin.org/docs/general/networking/index.html
  networking.firewall.allowedUDPPorts = [ 1900 7359 ];

  security.acme.certs.${domain} = { };

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  environment.persistence."/persist".directories = [
    "/var/lib/jellyfin"
    # also persist cache so we don't have to fetch metadata on every reboot
    "/var/cache/jellyfin"
  ];

  modules.services.restic.paths = [ "/var/lib/jellyfin" ];
}
