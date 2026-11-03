# Module for deploying umami analytics
{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "analytics.diogotc.com";
  port = lib.my.ports.umami;

  trackerScripts = [
    "script.js"
    "umami.js"
    "hellothere.js"
  ];
  collectApiEndpoint = "/api/abc-send";
in
{
  age.secrets = {
    umamiAppSecret.file = secrets.host.umamiAppSecret;
  };

  services.umami = {
    enable = true;
    createPostgresqlDatabase = true;
    settings = {
      HOSTNAME = "::1";
      PORT = port;

      TRACKER_SCRIPT_NAME = trackerScripts;
      COLLECT_API_ENDPOINT = collectApiEndpoint;

      APP_SECRET_FILE = config.age.secrets.umamiAppSecret.path;
      DISABLE_TELEMETRY = true;
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      serverAliases = [ "umami.diogotc.com" ];

      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };
}
