# hosts/bro/router.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Router configuration

{ pkgs, ... }:
let
  wanInterface = "eno1";
  lanInterface = "enp0s20f0u4";

  # /24 subnets
  privateSubnet = "192.168.1";
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

  networking.firewall = { trustedInterfaces = [ "br0" ]; };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = wanInterface;
  };

  networking.bridges.br0.interfaces = [ lanInterface ];

  networking.interfaces = {
    br0 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "${privateSubnet}.1";
        prefixLength = 24;
      }];
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

      interface = [ "br0" ];
      dhcp-range = [ "${privateSubnet}.50,${privateSubnet}.254,24h" ];
      dhcp-option = [
        # 0.0.0.0 below means "the server running dnsmasq"
        "option:router,0.0.0.0" # set default gateway
        "option:dns-server,0.0.0.0" # set dns server (to DoH proxy running on this server)
      ];
    };
  };
  modules.services.dnsoverhttps.all-interfaces = true;

  modules.impermanence.directories = [ "/var/lib/dnsmasq" ];
}
