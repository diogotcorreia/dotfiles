{ config, ... }:
let
  domain = "syncthing.hera.diogotc.com";
  cfg = config.services.syncthing;
in
{
  services.syncthing = {
    enable = true;
    group = config.services.nginx.group;
    systemService = true;
    overrideFolders = false;
    overrideDevices = false;
    settings = {
      gui = {
        theme = "dark";
        unixSocketPermissions = "0660";
      };
    };
    guiAddress = "/run/syncthing/syncthing.sock";
  };

  # ensure directories have correct ownership and perms
  systemd.services.syncthing.serviceConfig = {
    StateDirectory = "syncthing";
    StateDirectoryMode = "0700";
    RuntimeDirectory = "syncthing";
    RuntimeDirectoryMode = "0750";
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      autheliaRules = "group:syncthing-hera";
      restrictToNebula = true;
      autheliaHealthchecksPath = "/rest/noauth/health";
      locations."/" = {
        enableAuthelia = true;
        proxyPass = "http://unix:${cfg.guiAddress}";
      };
    };
  };

  modules.impermanence.directories = [ cfg.dataDir ];
  modules.services.restic.paths = [ cfg.configDir ];
}
