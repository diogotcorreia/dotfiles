# Pastebin server
{
  config,
  lib,
  secrets,
  ...
}: let
  domain = "bin.diogotc.com";
  port = lib.my.ports.wastebin;

  cfg = config.services.wastebin;
  stateDir = lib.my.toPrivateStateDirectory cfg.stateDir;
in {
  age.secrets.wastebinEnv.file = secrets.host.wastebinEnv;

  services.wastebin = {
    enable = true;

    settings = {
      WASTEBIN_TITLE = "dtc's wastebin";
      WASTEBIN_MAX_BODY_SIZE = 1024 * 1024; # 1MiB
      WASTEBIN_BASE_URL = "https://${domain}";
      WASTEBIN_ADDRESS_PORT = "[::1]:${toString port}";
      RUST_LOG = "info,wastebin=debug";
    };

    secretFile = config.age.secrets.wastebinEnv.path;
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  modules.impermanence.directories = [stateDir];

  modules.services.restic.paths = [stateDir];
}
