# URL shortner
{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "s.diogotc.com";
  port = lib.my.ports.chhotoUrl;

  stateDir = "/var/lib/private/chhoto-url";
in
{
  age.secrets.chhotoUrlEnv.file = secrets.host.chhotoUrlEnv;

  services.chhoto-url = {
    enable = true;
    environmentFiles = [
      # contains "password=<password>"
      config.age.secrets.chhotoUrlEnv.path
    ];
    settings = {
      inherit port;
      site_url = "https://${domain}";

      allow_capital_letters = true;
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  modules.impermanence.directories = [ stateDir ];

  modules.services.restic.paths = [ stateDir ];
}
