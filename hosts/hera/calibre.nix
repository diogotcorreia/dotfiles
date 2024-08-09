# Configuration for Calibre Web on Hera
{config, ...}: let
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

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
  };

  modules.impermanence.directories = [statePath];

  modules.services.restic.paths = [statePath libraryPath];
}
