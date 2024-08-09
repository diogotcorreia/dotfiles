# Configuration for bro (home server)
{
  config,
  lib,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.zfs-impermanence
    hardware.zram
    networking.ddns.cloudflare
    security.acme.cloudflare
    security.fail2ban
    services.caddy.common
    services.caddy.rproxy
    services.grocy
    services.ssh
  ];

  networking.hostId = "29e7efc9";

  my.filesystem.mainDisk = "/dev/sda";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  # Secret manager (agenix)
  age = {
    secrets = {
      broAutoUpgradeHealthchecksUrl.file = secrets.host.autoUpgradeHealthchecksUrl;
      broHealthchecksUrl.file = secrets.host.healthchecksUrl;
      broNebulaCert = {
        file = secrets.host.nebulaCert;
        owner = "nebula-nebula0";
      };
      broNebulaKey = {
        file = secrets.host.nebulaKey;
        owner = "nebula-nebula0";
      };
      broResticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
      broResticRcloneConfig.file = secrets.host.resticRcloneConfig;
      broResticPassword.file = secrets.host.resticPassword;
      broResticSshKey.file = secrets.host.resticSshKey;
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  my.networking.wiredInterface = "eno1";

  # Modules
  modules = {
    editors.neovim.enable = true;
    server = {
      enable = true;
      autoUpgradeCheckUrlFile =
        config.age.secrets.broAutoUpgradeHealthchecksUrl.path;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.broHealthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.broNebulaCert.path;
        key = config.age.secrets.broNebulaKey.path;
        firewall.inbound = [
          {
            port = 22;
            proto = "tcp";
            group = "dtc";
          }
          {
            port = 80;
            proto = "tcp";
            group = "dtc";
          }
          {
            port = 443;
            proto = "tcp";
            group = "dtc";
          }
          {
            # allow uptime server to ping services
            port = 443;
            proto = "tcp";
            group = "uptime";
          }
        ];
      };
      restic = {
        enable = true;
        checkUrlFile = config.age.secrets.broResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.broResticRcloneConfig.path;
        passwordFile = config.age.secrets.broResticPassword.path;
        sshKeyFile = config.age.secrets.broResticSshKey.path;

        timerConfig = {OnCalendar = "12:20";};
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      tmux.enable = true;
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
