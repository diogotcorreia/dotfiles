# Configuration for phobos (VPS)
{
  config,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    editors.neovim.base
    meta.server
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.infra-keyval
    services.nginx.common
    shell.zellij
  ];

  # Boot

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  # Configure static IPv6 address
  networking = {
    interfaces = {
      ${config.my.networking.wiredInterface}.ipv6.addresses = [
        {
          address = "2a03:4000:2a:1b3::";
          prefixLength = 64;
        }
      ];
    };
  };

  my.networking.wiredInterface = "ens3";

  # PostgreSQL
  services.postgresql.package = pkgs.postgresql_18;

  # Time zone
  time.timeZone = "UTC";

  # Modules
  modules = {
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
      };
      restic = {
        enable = true;

        timerConfig = {
          OnCalendar = "03:10";
        };
      };
    };
    shell = {
      git.enable = true;
      zsh.enable = true;
    };
  };

  # System state version
  system.stateVersion = "21.11";
}
