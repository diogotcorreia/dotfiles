# Configuration for bro (home server)
{
  config,
  hostSecretsDir,
  lib,
  profiles,
  ...
}: {
  imports = with profiles; [
    networking.ddns.cloudflare
    security.fail2ban
    services.caddy.common
    services.caddy.rproxy
    services.grocy
    services.ssh
  ];

  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  # Secret manager (agenix)
  age = {
    secrets = {
      broAcmeDnsCredentials = {
        file = "${hostSecretsDir}/acmeDnsCredentials.age";
        group = config.security.acme.defaults.group;
      };
      broAutoUpgradeHealthchecksUrl.file = "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      broHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      broNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      broNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      broResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      broResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      broResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      broResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # ACME certificates
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "bro-lets-encrypt@diogotc.com";
      dnsProvider = "cloudflare";

      # CLOUDFLARE_DNS_API_TOKEN=<token>
      credentialsFile = config.age.secrets.broAcmeDnsCredentials.path;
    };
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
    impermanence = {
      enable = true;
      # Impermanence (root on tmpfs)
      directories = ["/var/lib/acme"];
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
