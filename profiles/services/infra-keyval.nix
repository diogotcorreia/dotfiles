# Setup infra-keyval server
{
  config,
  inputs,
  secrets,
  ...
}: let
  domain = "infra-keyval.diogotc.com";
  port = 6442;
in {
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

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
      '';
    };
  };
}
