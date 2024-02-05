# hosts/bro/router.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Router configuration
{pkgs, ...}: let
  wanInterface = "eno1";
  lanInterface = "enp0s20f0u4";

  # /24 subnets
  privateSubnet = "192.168.1";
  iotCloudSubnet = "192.168.2";
  iotLocalSubnet = "192.168.3";
  guestSubnet = "192.168.4";
in {
  boot = {
    kernel = {
      sysctl = {
        # Forward on all interfaces.
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };
  };

  networking.useDHCP = false;
  networking.interfaces.${wanInterface}.useDHCP = true;
  networking.interfaces.${lanInterface}.useDHCP = true;

  networking.vlans = {
    # All my trusted devices
    vlan-private = {
      id = 10;
      interface = lanInterface;
    };
    # All IoT devices that need an internet connection (Google Home, smartwatch, etc)
    # They don't have access to the private vlan, with a few exceptions (see firewall rules)
    vlan-iot-cloud = {
      id = 20;
      interface = lanInterface;
    };
    # All IoT devices that work offline and only need to talk to Home Assistant
    vlan-iot-local = {
      id = 30;
      interface = lanInterface;
    };
    # Guests; full internet connection, but can't talk to one another nor to other vlans
    vlan-guest = {
      id = 40;
      interface = lanInterface;
    };
  };

  # TODO this needs way better rules
  networking.firewall = {
    trustedInterfaces = ["vlan-private"];
    interfaces = {
      vlan-iot-cloud = {
        allowedUDPPorts = [
          # DNS
          53
          # DHCP
          67
          68
        ];
      };
      vlan-iot-local = {
        allowedUDPPorts = [
          # DNS
          53
          # DHCP
          67
          68
        ];
      };
      vlan-guest = {
        allowedUDPPorts = [
          # DNS
          53
          # DHCP
          67
          68
        ];
      };
    };
  };

  networking.nat = {
    enable = true;
    internalInterfaces = ["vlan-private" "vlan-iot-cloud" "vlan-iot-local" "vlan-guest"];
    externalInterface = wanInterface;
  };

  networking.interfaces = {
    vlan-private = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "${privateSubnet}.1";
          prefixLength = 24;
        }
      ];
    };
    vlan-iot-cloud = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "${iotCloudSubnet}.1";
          prefixLength = 24;
        }
      ];
    };
    vlan-iot-local = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "${iotLocalSubnet}.1";
          prefixLength = 24;
        }
      ];
    };
    vlan-guest = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "${guestSubnet}.1";
          prefixLength = 24;
        }
      ];
    };
  };

  networking.networkmanager.enable = false;

  services.dnsmasq = {
    enable = true;
    settings = {
      port = 0; # disable DNS server
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;

      interface = ["vlan-private" "vlan-iot-cloud" "vlan-iot-local" "vlan-guest"];
      dhcp-range = [
        "${privateSubnet}.50,${privateSubnet}.254,24h"
        "${iotCloudSubnet}.50,${iotCloudSubnet}.254,24h"
        "${iotLocalSubnet}.50,${iotLocalSubnet}.254,24h"
        "${guestSubnet}.50,${guestSubnet}.254,24h"
      ];
      dhcp-option = [
        # 0.0.0.0 below means "the server running dnsmasq"
        "option:router,0.0.0.0" # set default gateway
        "option:dns-server,0.0.0.0" # set dns server (to DoH proxy running on this server)
      ];
    };
  };
  modules.services.dnsoverhttps.all-interfaces = true;

  modules.impermanence.directories = ["/var/lib/dnsmasq"];
}
