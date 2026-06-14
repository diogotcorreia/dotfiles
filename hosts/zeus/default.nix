# Configuration for zeus (VPS)
{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    editors.neovim.base
    hardware.filesystem.ext4-impermanence
    hardware.zram
    meta.server
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.nginx.common
    services.stalwart
    shell.zellij
  ];

  networking.hostId = "b6bd9436";
  my.filesystem.mainDisk = "/dev/sda";
  my.filesystem.espSize = "128M";
  my.filesystem.useEfi = false; # OVH does not support UEFI

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  # Configure static IPv6 address
  networking = {
    interfaces = {
      ${config.my.networking.wiredInterface}.ipv6.addresses = [
        {
          address = "2001:41d0:304:200::c76d";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway6 = {
      address = "2001:41d0:304:200::1";
      interface = config.my.networking.wiredInterface;
    };
  };

  my.networking.wiredInterface = "ens3";

  # PostgreSQL
  services.postgresql.package = pkgs.postgresql_18;

  # Time zone
  time.timeZone = "UTC";

  # Modules
  modules = {
    server.enable = true;
    services = {
      dnsoverhttps.enable = true;
      healthchecks.enable = true;
      # Nebula (VPN)
      nebula = {
        enable = true;
        isLighthouse = true;
        firewall.inbound = [
          {
            port = lib.my.ports.http;
            proto = "tcp";
            group = "dtc";
          }
          {
            port = lib.my.ports.https;
            proto = "tcp";
            group = "dtc";
          }
          {
            # allow uptime server to ping services
            port = lib.my.ports.https;
            proto = "tcp";
            group = "uptime";
          }
        ];
      };
      restic = {
        enable = true;

        timerConfig = {
          OnCalendar = "04:00";
        };
      };
    };
    shell = {
      git.enable = true;
    };
  };

  # System state version
  system.stateVersion = "25.11";
}
