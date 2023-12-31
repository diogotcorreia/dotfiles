# hosts/bro/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for bro (server).

{ pkgs, inputs, lib, sshKeys, config, hostSecretsDir, agenixPackage, ... }: {
  disabledModules = [ "services/misc/cfdyndns.nix" ];
  imports =
    [ (inputs.nixpkgs-unstable + "/nixos/modules/services/misc/cfdyndns.nix") ];

  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

  # Secret manager (agenix)
  age = {
    secrets = {
      broAcmeDnsCredentials = {
        file = "${hostSecretsDir}/acmeDnsCredentials.age";
        group = config.security.acme.defaults.group;
      };
      broAutoUpgradeHealthchecksUrl.file =
        "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      broCfdyndnsToken.file = "${hostSecretsDir}/cfdyndnsToken.age";
      broHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      broNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      broNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      broResticHealthchecksUrl.file =
        "${hostSecretsDir}/resticHealthchecksUrl.age";
      broResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      broResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      broResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [ ];

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    extraConfig = ''
      # Rules for services behind Cloudflare proxy
      (CLOUDFLARE_PROXY) {
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
      }

      # Rules for services behind Nebula VPN (192.168.100.1/24)
      (NEBULA) {
        # Nebula
        @not-nebula not remote_ip 192.168.100.1/24
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
  users.users.caddy.extraGroups = [ config.security.acme.defaults.group ];

  # Ensure nginx isn't turned on by some services (e.g. services using PHP)
  services.nginx.enable = lib.mkForce false;

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

  # Cloudflare Dynamic DNS
  services.cfdyndns = {
    enable = true;
    records = [ "world.bro.diogotc.com" ];
    apiTokenFile = config.age.secrets.broCfdyndnsToken.path;
  };

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

        timerConfig = { OnCalendar = "12:20"; };
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
      directories = [ "/var/lib/acme" "/var/lib/docker" ];
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
