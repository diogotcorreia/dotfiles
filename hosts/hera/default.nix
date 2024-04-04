# Configuration for hera (home server)
{
  config,
  hostSecretsDir,
  inputs,
  lib,
  pkgs,
  profiles,
  ...
}: {
  # Fix Docker containers not gracefully shutting down
  # https://github.com/NixOS/nixpkgs/pull/248315
  # TODO remove in nixos-24.05
  disabledModules = ["virtualisation/oci-containers.nix"];
  imports =
    [
      (inputs.nixpkgs-unstable + "/nixos/modules/virtualisation/oci-containers.nix")
    ]
    ++ (with profiles; [
      services.ssh
    ]);

  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  networking = {
    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "192.168.1.3";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eno1";
    };
    nat = {
      enable = true;
      externalInterface = "eno1";
    };
  };

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

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [80 443];
  services.caddy = {
    enable = true;
    extraConfig = ''
      # Rules for services behind Cloudflare proxy
      (CLOUDFLARE_PROXY) {
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
      }

      # Rules for services behind Nebula VPN (192.168.100.1/24)
      (NEBULA) {
        # Nebula + Docker
        @not-nebula not remote_ip 192.168.100.1/24 172.16.0.0/12
        abort @not-nebula
      }

      # Rules for services behind Authelia
      (AUTHELIA) {
        @not_healthchecks {
          not {
            method GET
            path /
            remote_ip 192.168.100.7 # phobos
          }
        }
        forward_auth @not_healthchecks 192.168.100.1:9091 {
          uri /api/verify?rd=https://auth.diogotc.com/
          copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
      }

    '';
  };
  users.users.caddy.extraGroups = [config.security.acme.defaults.group];

  # Ensure nginx isn't turned on by some services (e.g. services using PHP)
  services.nginx.enable = lib.mkForce false;

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
