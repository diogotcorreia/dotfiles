# Configuration for hera (home server)
{
  config,
  lib,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.zfs-impermanence
    hardware.fwupd
    hardware.zram
    security.acme.cloudflare
    security.fail2ban
    security.secureboot
    services.caddy.common
    services.dashy
    services.discord-bots.alt-urls-discord-bot
    services.ssh
    shell.zellij
    virtualisation.docker
  ];

  # Host Id
  networking.hostId = "93ae55de";

  my.filesystem.mainDisk = "/dev/nvme0n1";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  networking = {
    interfaces.${config.my.networking.wiredInterface} = {
      ipv4.addresses = [
        {
          address = "192.168.1.3";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = config.my.networking.wiredInterface;
    };
    nat = {
      enable = true;
      externalInterface = config.my.networking.wiredInterface;
    };
  };

  my.networking.wiredInterface = "enp0s31f6";

  # Secret manager (agenix)
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

  # PostgreSQL
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
  };

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

        # TODO each service should define its own paths
        paths = [
          "${config.my.homeDirectory}/dailytxt"
          "${config.my.homeDirectory}/grafana"
        ];
        exclude = ["**/node_modules" "**/.npm"];

        timerConfig = {OnCalendar = "03:05";};
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      zsh.enable = true;
    };
    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
  };

  # System state version
  system.stateVersion = "23.05";
}
