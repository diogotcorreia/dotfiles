# Configuration for feb (home server)
{
  config,
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
  age = {
    secrets = {
      autoUpgradeHealthchecksUrl.file = secrets.host.autoUpgradeHealthchecksUrl;
      healthchecksUrl.file = secrets.host.healthchecksUrl;
      nebulaCert = {
        file = secrets.host.nebulaCert;
        owner = "nebula-nebula0";
      };
      nebulaKey = {
        file = secrets.host.nebulaKey;
        owner = "nebula-nebula0";
      };
      resticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
      resticRcloneConfig.file = secrets.host.resticRcloneConfig;
      resticPassword.file = secrets.host.resticPassword;
      resticSshKey.file = secrets.host.resticSshKey;
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  my.networking.wiredInterface = "enp0s31f6";

  # Modules
  modules = {
    editors.neovim.enable = true;
    server = {
      enable = true;
      autoUpgradeCheckUrlFile = config.age.secrets.autoUpgradeHealthchecksUrl.path;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.healthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.nebulaCert.path;
        key = config.age.secrets.nebulaKey.path;
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
        checkUrlFile = config.age.secrets.resticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.resticRcloneConfig.path;
        passwordFile = config.age.secrets.resticPassword.path;
        sshKeyFile = config.age.secrets.resticSshKey.path;

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
