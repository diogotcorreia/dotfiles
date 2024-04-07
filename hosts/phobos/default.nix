# Configuration for phobos (VPS)
{
  config,
  hostSecretsDir,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
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
      phobosAutoUpgradeHealthchecksUrl.file = "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      phobosHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      phobosNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      phobosNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      phobosResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      phobosResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      phobosResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      phobosResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/root/.ssh/id_ed25519"];
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [];

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [80 443];
  services.caddy = {
    enable = true;
    email = "phobos-lets-encrypt@diogotc.com";
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

  # Statem state version
  system.stateVersion = "21.11";
}
