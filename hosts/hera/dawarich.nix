# Configuration for Dawarich (Location Timeline) on Hera
{
  config,
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

  # TODO: remove on 25.11
  # Compatibility with 25.11 modules due to changes in PostgreSQL module
  systemd.targets.postgresql = {
    description = "PostgreSQL";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "postgresql.service"
      "postgresql-setup.service"
    ];
  };
  systemd.services.postgresql = {
    wants = [ "postgresql.target" ];
    partOf = [ "postgresql.target" ];
  };
  systemd.services.postgresql-setup = {
    description = "PostgreSQL Setup Scripts";

    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
    serviceConfig = {
      User = "postgres";
      Group = "postgres";
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ config.services.postgresql.finalPackage ];
    environment.PGPORT = builtins.toString config.services.postgresql.settings.port;
    script = ''
      echo dummy
    '';
  };

  modules.services.restic.paths = [
    "/var/lib/dawarich"
  ];
}
