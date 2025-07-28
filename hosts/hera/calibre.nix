# Configuration for Calibre Web on Hera
{
  config,
  lib,
  ...
}:
let
  domain = "calibre.diogotc.com";
  port = lib.my.ports.calibreWeb;

  statePath = "/var/lib/${config.services.calibre-web.dataDir}";
  libraryPath = "/persist/calibre-library";
in
{
  services.calibre-web = {
    enable = true;
    listen = {
      ip = "::1";
      inherit port;
    };
    options = {
      calibreLibrary = libraryPath;
      enableBookConversion = true;
      enableBookUploading = true;
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };
  };

  modules.impermanence.directories = [ statePath ];

  modules.services.restic.paths = [
    statePath
    libraryPath
  ];
}
