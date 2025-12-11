# Configuration for Paperless-ngx on Hera
{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "paperless.diogotc.com";
  port = lib.my.ports.paperless;

  dataDir = config.services.paperless.dataDir;

  dbUser = config.services.paperless.user;
in
{
  services.paperless = {
    enable = true;
    address = "::1";
    inherit port;

    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng+por+swe";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
        # Allow OCRmyPDF to modify signed PDFs, since original is also stored
        # https://github.com/paperless-ngx/paperless-ngx/issues/7383
        invalidate_digital_signatures = true;
      };

      PAPERLESS_URL = "https://${domain}";
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ dbUser ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  modules.impermanence.directories = [ dataDir ];

  modules.services.restic.paths = [ dataDir ];
  modules.services.restic.exclude = [ "${dataDir}/log" ];
}
