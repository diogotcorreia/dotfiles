# hosts/hera/transmission.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Transmission on Hera

{ pkgs, config, ... }:
let
  domain = "transmission.hera.diogotc.com";
  port = 9091;
in {

  # TODO move docker containers to NixOS services

  security.acme.certs.${domain} = { };

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  modules.services.restic = {
    paths = [ "${config.my.homeDirectory}/transmission-openvpn" ];
    exclude = [
      "${config.my.homeDirectory}/transmission-openvpn/data/completed"
      "${config.my.homeDirectory}/transmission-openvpn/data/incomplete"

    ];
  };
}
