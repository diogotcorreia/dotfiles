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
  noderedDomain = "nodered.hera.diogotc.com";
  noderedPort = 1880;
in {

  # TODO move docker containers to NixOS services

  networking.firewall = {
    # UDP Port 5353 for mDNS discovery of Google Cast devices (Spotify)
    # UDP Port 5683 for CoIoT (Shelly push)
    allowedUDPPorts = [ 5353 5683 ];

    # TCP Port 8095 for Music Assistant
    allowedTCPPorts = [ 8095 hassPort ];
  };

  security.acme.certs = {
    ${hassDomain} = { };
    ${noderedDomain} = { };
  };

  services.caddy.virtualHosts = {
    ${hassDomain} = {
      useACMEHost = hassDomain;
      extraConfig = ''
        reverse_proxy localhost:${toString hassPort} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
    ${noderedDomain} = {
      useACMEHost = noderedDomain;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString noderedPort}
      '';
    };
  };

  modules.services.restic.paths =
    [ "${config.my.homeDirectory}/homeassistant" ];
}
