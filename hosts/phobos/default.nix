# Configuration for phobos (VPS)
{
  config,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    security.fail2ban
    services.caddy.common
    services.ssh
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
    defaultGateway6 = {
      address = "fe80::1";
      interface = config.my.networking.wiredInterface;
    };
  };

  my.networking.wiredInterface = "ens3";

  # Secret manager (agenix)
  age = {
    secrets = {
      phobosAutoUpgradeHealthchecksUrl.file = secrets.host.autoUpgradeHealthchecksUrl;
      phobosHealthchecksUrl.file = secrets.host.healthchecksUrl;
      phobosNebulaCert = {
        file = secrets.host.nebulaCert;
        owner = "nebula-nebula0";
      };
      phobosNebulaKey = {
        file = secrets.host.nebulaKey;
        owner = "nebula-nebula0";
      };
      phobosResticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
      phobosResticRcloneConfig.file = secrets.host.resticRcloneConfig;
      phobosResticPassword.file = secrets.host.resticPassword;
      phobosResticSshKey.file = secrets.host.resticSshKey;
    };

    identityPaths = ["/root/.ssh/id_ed25519"];
  };

  # PostgreSQL
  services.postgresql.enable = true;

  # Modules
  modules = {
    editors.neovim.enable = true;
    server = {
      enable = true;
      autoUpgradeCheckUrlFile =
        config.age.secrets.phobosAutoUpgradeHealthchecksUrl.path;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosHealthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.phobosNebulaCert.path;
        key = config.age.secrets.phobosNebulaKey.path;
        isLighthouse = true;
      };
      restic = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.phobosResticRcloneConfig.path;
        passwordFile = config.age.secrets.phobosResticPassword.path;
        sshKeyFile = config.age.secrets.phobosResticSshKey.path;

        timerConfig = {OnCalendar = "03:10";};
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
  };

  # System state version
  system.stateVersion = "21.11";
}
