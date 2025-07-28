# Setup infra-keyval server
{
  config,
  inputs,
  lib,
  secrets,
  ...
}:
let
  domain = "infra-keyval.diogotc.com";
  port = lib.my.ports.infraKeyval;
in
{
  imports = [
    inputs.infra-keyval.nixosModules.infra-keyval
  ];

  age.secrets.infraKeyvalEnv.file = secrets.host.infraKeyvalEnv;

  services.infra-keyval = {
    inherit port;

    enable = true;
    configureDatabase = true;

    # contains WRITE_TOKEN
    settingsFile = config.age.secrets.infraKeyvalEnv.path;
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };
}
