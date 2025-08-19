# Configuration for bro (home server)
{
  lib,
  profiles,
  ...
}:
{
  imports = with profiles; [
    hardware.filesystem.zfs-impermanence
    hardware.zram
    meta.server
    networking.ddns.cloudflare
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.frp.client
    services.frp.server
    services.nginx.common
    services.grocy
    shell.zellij
    virtualisation.virtual-machines
  ];

  networking.hostId = "29e7efc9";

  my.filesystem.mainDisk = "/dev/sda";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  networking.bridges.br-wan.interfaces = [ "eno1" ];
  my.networking.wiredInterface = "br-wan";

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

        timerConfig = {
          OnCalendar = "12:20";
        };
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      zsh.enable = true;
    };
  };

  # Override server.nix module settings
  system.autoUpgrade = {
    rebootWindow = {
      lower = lib.mkForce "12:00";
      upper = lib.mkForce "14:00";
    };
    dates = lib.mkForce "12:00";
  };

  # System state version
  system.stateVersion = "23.05";
}
