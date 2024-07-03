# Configuration for hera (home server)
{
  config,
  pkgs,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.zfs-impermanence
    hardware.zram
    security.fail2ban
    services.caddy.common
    services.ssh
    virtualisation.docker
  ];

  # Host Id
  networking.hostId = "9832f4c7";

  my.filesystem.mainDisk = "/dev/sda";

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

  my.networking.wiredInterface = "eno1";

  # Secret manager (agenix)
  age = {
    secrets = {
      diskstationSambaCredentials.file = secrets.host.diskstationSambaCredentials;
      heraAcmeDnsCredentials = {
        file = secrets.host.acmeDnsCredentials;
        group = config.security.acme.defaults.group;
      };
      heraAutoUpgradeHealthchecksUrl.file = secrets.host.autoUpgradeHealthchecksUrl;
      heraHealthchecksUrl.file = secrets.host.healthchecksUrl;
      heraNebulaCert = {
        file = secrets.host.nebulaCert;
        owner = "nebula-nebula0";
      };
      heraNebulaKey = {
        file = secrets.host.nebulaKey;
        owner = "nebula-nebula0";
      };
      heraResticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
      heraResticRcloneConfig.file = secrets.host.resticRcloneConfig;
      heraResticPassword.file = secrets.host.resticPassword;
      heraResticSshKey.file = secrets.host.resticSshKey;
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # Keep laptop on when lid is closed
  services.logind.lidSwitch = "ignore";

  # ACME certificates
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "hera-lets-encrypt@diogotc.com";
      dnsProvider = "cloudflare";

      # CLOUDFLARE_DNS_API_TOKEN=<token>
      credentialsFile = config.age.secrets.heraAcmeDnsCredentials.path;
    };
  };

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
      autoUpgradeCheckUrlFile =
        config.age.secrets.heraAutoUpgradeHealthchecksUrl.path;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.heraHealthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.heraNebulaCert.path;
        key = config.age.secrets.heraNebulaKey.path;
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
        checkUrlFile = config.age.secrets.heraResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.heraResticRcloneConfig.path;
        passwordFile = config.age.secrets.heraResticPassword.path;
        sshKeyFile = config.age.secrets.heraResticSshKey.path;

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
      tmux.enable = true;
      zsh.enable = true;
    };
    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/acme"
      ];
    };
  };

  # System state version
  system.stateVersion = "23.05";
}
