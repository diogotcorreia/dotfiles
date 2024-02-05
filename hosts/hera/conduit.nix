# hosts/hera/conduit.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Conduit (Matrix Homeserver) on Hera
{
  pkgs,
  config,
  ...
}: let
  domainConduit = "m.diogotc.com";
  portConduit = 6167;
  domainElement = "chat.diogotc.com";
  portElement = 8012;
in {
  # TODO move docker containers to NixOS services

  security.acme.certs = {
    ${domainConduit} = {};
    ${domainElement} = {};
  };

  services.caddy.virtualHosts = {
    ${domainConduit} = {
      useACMEHost = domainConduit;
      extraConfig = ''
        header /.well-known/matrix/* Content-Type application/json
        header /.well-known/matrix/* Access-Control-Allow-Origin *
        respond /.well-known/matrix/server `{"m.server": "m.diogotc.com:443"}`
        respond /.well-known/matrix/client `{"m.homeserver": {"base_url": "https://m.diogotc.com"}, "org.matrix.msc3575.proxy": {"url": "https://m.diogotc.com"}}`
        reverse_proxy /_matrix/* localhost:${toString portConduit} {
          import CLOUDFLARE_PROXY
        }
        reverse_proxy /_synapse/client/* localhost:${toString portConduit} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
    ${domainElement} = {
      useACMEHost = domainElement;
      extraConfig = ''
        reverse_proxy localhost:${toString portElement} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  modules.services.restic.paths = ["${config.my.homeDirectory}/conduit"];
}
