# Configuration for Dawarich (Location Timeline) on Hera
{
  inputs,
  lib,
  ...
}:
let
  domain = "location.diogotc.com";
  port = lib.my.ports.dawarich;
in
{
  imports = [
    (inputs.nixpkgs-dawarich-pr + "/nixos/modules/services/web-apps/dawarich.nix")
  ];

  services.dawarich = {
    enable = true;
    webPort = port;
    localDomain = domain;
    extraConfig = {
      STORE_GEODATA = "true";
      PHOTON_API_HOST = "photon.komoot.io";
      PHOTON_API_USE_HTTPS = "true";
      ENABLE_TELEMETRY = "false";
    };
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    autheliaRules = "group:location";
    # Require auth for everything except upload and health endpoints
    locations = {
      "/" = {
        enableAuthelia = true;
      };
      "= /api/v1/owntracks/points" = {
        tryFiles = "$uri @proxy";
        extraConfig = ''
          limit_except POST {
            deny all;
          }
        '';
      };
      "= /api/v1/health" = {
        tryFiles = "$uri @proxy";
        extraConfig = ''
          limit_except GET {
            deny all;
          }
        '';
      };
    };
  };

  modules.services.restic.paths = [
    "/var/lib/dawarich"
  ];
}
