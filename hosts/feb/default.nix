# Configuration for feb (home server)
{
  config,
  hostSecretsDir,
  profiles,
  ...
}: {
  imports = with profiles; [
    networking.ddns.cloudflare
    security.fail2ban
    services.caddy.common
    services.ssh
  ];

  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Lisbon";

  # Secret manager (agenix)
  age = {
    secrets = {
      autoUpgradeHealthchecksUrl.file = "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      cloudflareToken.file = "${hostSecretsDir}/cloudflareToken.age";
      healthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      nebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      nebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      resticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      resticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      resticPassword.file = "${hostSecretsDir}/resticPassword.age";
      resticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # ACME certificates
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "feb-lets-encrypt@diogotc.com";
      dnsProvider = "cloudflare";
      credentialFiles = {
        CLOUDFLARE_DNS_API_TOKEN_FILE = config.age.secrets.cloudflareToken.path;
      };
    };
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
      tmux.enable = true;
      zsh.enable = true;
    };
    impermanence = {
      enable = true;
      # Impermanence (root on tmpfs)
      directories = ["/var/lib/acme"];
    };
  };

  # System state version
  system.stateVersion = "24.05";
}
