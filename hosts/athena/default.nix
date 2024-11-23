# Configuration for athena (VPS)
{
  config,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    hardware.filesystem.ext4-impermanence
    hardware.zram
    security.acme.cloudflare
    security.fail2ban
    services.caddy.common
    services.meilisearch
    services.ssh
    services.stalwart-mail
    services.umami
    shell.zellij
    virtualisation.docker
  ];

  networking.hostId = "4d44f5a9";
  my.filesystem.mainDisk = "/dev/sda";
  my.filesystem.espSize = "128M";
  my.filesystem.useEfi = false; # OVH does not support UEFI

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  # Configure static IPv6 address
  networking = {
    interfaces = {
      ${config.my.networking.wiredInterface}.ipv6.addresses = [
        {
          address = "2001:41d0:304:200::34e7";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway6 = {
      address = "2001:41d0:304:200::1";
      interface = config.my.networking.wiredInterface;
    };
  };

  my.networking.wiredInterface = "ens3";

  # Time zone
  time.timeZone = "UTC";

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

    identityPaths = ["${config.modules.impermanence.persistDirectory}/etc/ssh/ssh_host_ed25519_key"];
  };

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

        timerConfig = {OnCalendar = "04:00";};
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
