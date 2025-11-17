# Module for deploying umami analytics
{
  config,
  inputs,
  lib,
  pkgs,
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
  imports = [
    # TODO 25.11: use stable
    (inputs.nixpkgs-unstable + "/nixos/modules/services/web-apps/umami.nix")
  ];

  age.secrets = {
    umamiAppSecret.file = secrets.host.umamiAppSecret;
  };

  services.umami = {
    enable = true;
    package = pkgs.unstable.umami; # TODO 25.11: use stable
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
