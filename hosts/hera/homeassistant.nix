# hosts/hera/homeassistant.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Home Assistant (and related programs) on Hera

{ pkgs, config, ... }:
let
  hassDomain = "hass.diogotc.com";
  hassPort = 8123;
in {

  # TODO move docker containers to NixOS services

  networking.firewall = {
    # UDP Port 5683 for CoIoT (Shelly push)
    allowedUDPPorts = [ 5683 ];

    # TCP Port 8095 for Music Assistant
    allowedTCPPorts = [ 8095 ];
  };

  security.acme.certs.${hassDomain} = { };

  services.caddy.virtualHosts.${hassDomain} = {
    useACMEHost = hassDomain;
    extraConfig = ''
      reverse_proxy localhost:${toString hassPort} {
        import CLOUDFLARE_PROXY
      }
    '';
  };

  modules.services.restic.paths =
    [ "${config.my.homeDirectory}/homeassistant" ];
}
