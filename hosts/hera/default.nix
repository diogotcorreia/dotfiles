# Configuration for hera (home server)
{
  config,
  hostSecretsDir,
  pkgs,
  profiles,
  ...
}: {
  imports = (with profiles; [
      services.caddy.common
      services.ssh
    ]);

  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

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

  # Docker (containers)
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  # Secret manager (agenix)
  age = {
    secrets = {
      diskstationSambaCredentials.file = "${hostSecretsDir}/diskstationSambaCredentials.age";
      heraAcmeDnsCredentials = {
        file = "${hostSecretsDir}/acmeDnsCredentials.age";
        group = config.security.acme.defaults.group;
      };
      heraAutoUpgradeHealthchecksUrl.file = "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      heraHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      heraNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      heraNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      heraResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      heraResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      heraResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      heraResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [];

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
      enable = true;
      # Impermanence (root on tmpfs)
      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/acme"
        "/var/lib/docker"
      ];
    };
  };

  # Statem state version
  system.stateVersion = "23.05";
}
