# Configuration for athena (VPS)
{
  config,
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.ext4-impermanence
    hardware.zram
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.authelia
    services.battleship-js
    services.chhoto-url
    services.discord-bots.triton-bot
    services.dtc-labs
    services.gpg-wkd
    services.lldap
    services.meilisearch
    services.nginx.common
    services.pairdrop
    services.reposilite
    services.resumos-legacy
    services.rex-cdn
    services.ssh
    services.twin
    services.umami
    services.wastebin
    shell.zellij
  ];

  networking.hostId = "4d44f5a9";
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
          address = "2001:41d0:304:200::34e7";
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

  # Time zone
  time.timeZone = "UTC";

  # Secret manager (agenix)
  age.identityPaths = ["${config.modules.impermanence.persistDirectory}/etc/ssh/ssh_host_ed25519_key"];

  # Modules
  modules = {
    editors.neovim.enable = true;
    server = {
      enable = true;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        isLighthouse = true;
        firewall.inbound = [
          {
            port = lib.my.ports.ssh;
            proto = "tcp";
            group = "dtc";
          }
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

        timerConfig = {OnCalendar = "04:00";};
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      zsh.enable = true;
    };
  };

  # System state version
  system.stateVersion = "24.05";
}
