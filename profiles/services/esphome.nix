{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  domain = "esphome.${config.networking.hostName}.diogotc.com";

  stateDir = lib.my.toPrivateStateDirectory "/var/lib/esphome";
in
{
  # Use module from nixos-unstable
  disabledModules = [
    "services/home-automation/esphome.nix"
  ];
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/home-automation/esphome.nix")
  ];

  services.esphome = {
    enable = true;
    enableUnixSocket = true;
    package = pkgs.unstable.esphome;
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

  systemd.services.esphome =
    let
      cacheDir = "/var/cache/esphome";
    in
    {
      environment = {
        # Fix UV trying to write to /var/empty
        UV_CACHE_DIR = "${cacheDir}/uv";
        # Move build dirs to cache directory instead
        PLATFORMIO_CACHE_DIR = "${cacheDir}/platformio";
        ESPHOME_BUILD_PATH = "${cacheDir}/build";
      };
      serviceConfig = {
        CacheDirectory = "esphome";
        CacheDirectoryMode = "0750";
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

  modules.impermanence.directories = [
    stateDir
  ];

  modules.services.restic = {
    paths = [
      stateDir
    ];
    exclude = [
      "${stateDir}/.platformio"
      "${stateDir}/.esphome/build"
      "${stateDir}/.esphome/.espressif"
    ];
  };
}
