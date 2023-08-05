# hosts/hera/calibre.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Calibre Web on Hera

{ pkgs, config, ... }:
let
  domain = "calibre.diogotc.com";
  port = 8011;

  statePath = "/var/lib/${config.services.calibre-web.dataDir}";
  libraryPath = "/persist/calibre-library";
in {
  services.calibre-web = {
    enable = true;
    listen = {
      ip = "127.0.0.1";
      inherit port;
    };
    options = {
      calibreLibrary = libraryPath;
      enableBookConversion = true;
      enableBookUploading = true;
    };
  };

  security.acme.certs.${domain} = { };

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  environment.persistence."/persist".directories = [ statePath ];

  modules.services.restic.paths = [ statePath libraryPath ];
}
