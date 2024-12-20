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
    hardware.fwupd
    hardware.zram
    security.acme.cloudflare
    security.fail2ban
    security.secureboot
    services.caddy.common
    services.discord-bots.alt-urls-discord-bot
    services.ssh
    shell.zellij
    virtualisation.docker
  ];

  # Host Id
  networking.hostId = "93ae55de";

  my.filesystem.mainDisk = "/dev/nvme0n1";

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

  my.networking.wiredInterface = "enp0s31f6";

  # Secret manager (agenix)
  age = {
    secrets = {
      diskstationSambaCredentials.file = secrets.host.diskstationSambaCredentials;
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
      zsh.enable = true;
    };
    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
  };

  # System state version
  system.stateVersion = "23.05";
}
