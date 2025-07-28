{
  config,
  lib,
  ...
}:
let
  domain = "esphome.${config.networking.hostName}.diogotc.com";
in
{
  services.esphome = {
    enable = true;
    enableUnixSocket = true;
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      restrictToNebula = true;
      autheliaHealthchecksPath = "/ping";
      autheliaRules = "group:esphome-${config.networking.hostName}";
      locations."/" = {
        enableAuthelia = true;
        proxyPass = "http://unix:/run/esphome/esphome.sock";
      };
    };
  };

  # allow access to socket
  # if user is not created as well, unit will not start, due to DynamicUser
  users.users.esphome = lib.mkIf (config.services.nginx.enable) {
    isSystemUser = true;
    group = "esphome";
  };
  users.groups.esphome = lib.mkIf (config.services.nginx.enable) {
    members = [ "nginx" ];
  };
}
