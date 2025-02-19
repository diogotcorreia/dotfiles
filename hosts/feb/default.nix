# Configuration for feb (home server)
{
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.zfs-impermanence
    hardware.zram
    networking.ddns.cloudflare
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.caddy.common
    services.ssh
    shell.zellij
  ];

  networking.hostId = "1215a7f5";
  my.filesystem.mainDisk = "/dev/nvme0n1";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Lisbon";

  # Secret manager (agenix)
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];

  my.networking.wiredInterface = "enp0s31f6";

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

        timerConfig = {OnCalendar = "03:00";};
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
