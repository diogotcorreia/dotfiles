# Configuration for phobos (VPS)
{
  config,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    meta.server
    security.acme.cloudflare
    security.fail2ban
    server.minimal
    services.caddy.common
    services.infra-keyval
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

  # Time zone
  time.timeZone = "UTC";

  # Secret manager (agenix)
  age.identityPaths = ["/root/.ssh/id_ed25519"];

  # PostgreSQL
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
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
        isLighthouse = true;
      };
      restic = {
        enable = true;

        timerConfig = {OnCalendar = "03:10";};
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      zsh.enable = true;
    };
  };

  # System state version
  system.stateVersion = "21.11";
}
