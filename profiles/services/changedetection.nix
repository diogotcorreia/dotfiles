# Profile for changedetection.io
{
  config,
  lib,
  ...
}:
let
  domain = "changedetection.bro.diogotc.com";
  port = lib.my.ports.changedetection-io;
in
{
  services.changedetection-io = {
    enable = true;
    behindProxy = true;
    listenAddress = "::1";
    inherit port;
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      autheliaRules = "group:changedetection";
      restrictToNebula = true;
      autheliaHealthchecksPath = "/api/v1/systeminfo";
      locations."/" = {
        enableAuthelia = true;
        proxyPass = "http://[::1]:${toString port}";
      };
    };
  };

  modules.impermanence.directories = [
    config.services.changedetection-io.datastorePath
  ];
  modules.services.restic.paths = [
    config.services.changedetection-io.datastorePath
  ];
}
