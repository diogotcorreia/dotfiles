# Configuration for Home Assistant (and related programs) on Hera
{
  config,
  lib,
  ...
}: let
  hassDomain = "hass.diogotc.com";
  hassPort = lib.my.ports.homeAssistant;
  noderedDomain = "nodered.hera.diogotc.com";
  noderedPort = lib.my.ports.nodered;
in {
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

  services.caddy.virtualHosts = {
    ${hassDomain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString hassPort} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
    ${noderedDomain} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString noderedPort}
      '';
    };
  };

  my.services.authelia.accessRules = [
    {
      domain = noderedDomain;
      subject = "group:nodered-hera";
    }
  ];

  modules.services.restic.paths = ["${config.my.homeDirectory}/homeassistant"];
}
