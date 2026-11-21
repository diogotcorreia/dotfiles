# Configuration for phobos (VPS)
{
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    editors.neovim.base
    meta.server
    monitoring.grafana
    monitoring.prometheus
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
    };
  };

  # System state version
  system.stateVersion = "26.05";
}
