# Pastebin server
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  domain = "bin.diogotc.com";
  port = lib.my.ports.wastebin;

  stateDir = "/var/lib/private/wastebin";
in {
  age.secrets.wastebinEnv.file = secrets.host.wastebinEnv;

  services.wastebin = {
    enable = true;
    # TODO 25.05: change to stable
    package = pkgs.unstable.wastebin;

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
