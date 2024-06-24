# Configuration for Home Assistant (and related programs) on Hera
{config, ...}: let
  hassDomain = "hass.diogotc.com";
  hassPort = 8123;
  noderedDomain = "nodered.hera.diogotc.com";
  noderedPort = 1880;
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
    # UDP Port 5353 for mDNS discovery of Google Cast devices (Spotify)
    # UDP Port 5683 for CoIoT (Shelly push)
    allowedUDPPorts = [5353 5683];

    # TCP Ports 8095 and 8097 for Music Assistant
    allowedTCPPorts = [8095 8097 hassPort];
  };

  security.acme.certs = {
    ${hassDomain} = {};
    ${noderedDomain} = {};
  };

  services.caddy.virtualHosts = {
    ${hassDomain} = {
      useACMEHost = hassDomain;
      extraConfig = ''
        reverse_proxy localhost:${toString hassPort} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
    ${noderedDomain} = {
      useACMEHost = noderedDomain;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString noderedPort}
      '';
    };
  };

  modules.services.restic.paths = ["${config.my.homeDirectory}/homeassistant"];
}
