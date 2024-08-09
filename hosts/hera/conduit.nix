# Configuration for Conduit (Matrix Homeserver) on Hera
{config, ...}: let
  domainConduit = "m.diogotc.com";
  portConduit = 6167;
  domainElement = "chat.diogotc.com";
  portElement = 8012;
in {
  # TODO move docker containers to NixOS services

  services.caddy.virtualHosts = {
    ${domainConduit} = {
      enableACME = true;
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
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString portElement} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  modules.services.restic.paths = ["${config.my.homeDirectory}/conduit"];
}
