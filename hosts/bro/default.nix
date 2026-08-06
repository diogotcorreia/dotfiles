# Configuration for bro (home server)
{
  lib,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    editors.neovim.base
    hardware.filesystem.zfs-impermanence
    hardware.zram
    meta.server
    networking.ddns.cloudflare
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.changedetection
    services.frp.client
    services.frp.server
    services.nginx.common
    services.grocy
    shell.zellij
    virtualisation.virtual-machines
  ];

  networking.hostId = "29e7efc9";

  my.filesystem.mainDisk = "/dev/sda";

  # PostgreSQL
  services.postgresql.package = pkgs.postgresql_18;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  networking.bridges.br-wan.interfaces = [ "eno1" ];
  my.networking.wiredInterface = "br-wan";

  # Modules
  modules = {
    server = {
      enable = true;
    };
    services = {
      healthchecks = {
        enable = true;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
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
          OnCalendar = "12:20";
        };
      };
      wireguard-server = {
        enable = true;
        subnet = "192.168.102";
        peers = (
          with lib.my.wireguard-keys;
          [
            {
              publicKey = bluejay;
              lastOctect = 2;
            }
            {
              publicKey = bacchus;
              lastOctect = 3;
            }
            {
              publicKey = rso-rotterdam;
              lastOctect = 50;
            }
          ]
        );
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
    };
  };

  # System state version
  system.stateVersion = "26.05";
}
