# Configuration for Home Assistant (and related programs) on Hera
{
  config,
  lib,
  ...
}:
let
  hassDomain = "hass.diogotc.com";
  hassPort = lib.my.ports.homeAssistant;
  noderedDomain = "nodered.hera.diogotc.com";
  noderedPort = lib.my.ports.nodered;
in
{
  # TODO move docker containers to NixOS services

  # https://github.com/esphome/issues/issues/2669
  boot = {
    kernel = {
      sysctl = {
        # Forward on all interfaces.
        "net.ipv4.igmp_max_memberships" = 50;
        "net.ipv6.igmp_max_msf" = 30;
      };
    };
  };

  networking.firewall = {
    # UDP Port for mDNS discovery of Google Cast devices (Spotify)
    # UDP Port for CoIoT (Shelly push)
    allowedUDPPorts = with lib.my.ports; [
      mdnsGoogleCast
      coiot
    ];

    allowedTCPPorts = with lib.my.ports; [
      musicAssistantWeb
      musicAssistantAudioStream
      hassPort
    ];
  };

  services.nginx.virtualHosts = {
    ${hassDomain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString hassPort}";
    };
    ${noderedDomain} = {
      enableACME = true;
      restrictToNebula = true;
      autheliaRules = "group:nodered-hera";
      autheliaHealthchecksPath = "/settings";
      locations."/" = {
        enableAuthelia = true;
        proxyPass = "http://127.0.0.1:${toString noderedPort}";
      };
    };
  };

  modules.services.restic.paths = [ "${config.my.homeDirectory}/homeassistant" ];
}
