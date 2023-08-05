# hosts/hera/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for hera (server).

{ pkgs, lib, sshKeys, config, hostSecretsDir, agenixPackage, ... }:
let diskstationAddress = "192.168.1.4";
in {
  # Impermanence (root on tmpfs)
  environment.persistence."/persist" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/var/lib/systemd"
      "/var/log"
    ];
    files =
      [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_ed25519_key.pub" ];
  };

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  networking = {
    interfaces.eno1 = {
      ipv4.addresses = [{
        address = "192.168.1.3";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "eno1";
    };
  };

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

  # NAS mounts
  fileSystems."/media/diskstation" = {
    device = "//${diskstationAddress}/video";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts =
        "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in [
      "${automount_opts},vers=2.0,credentials=${config.age.secrets.diskstationSambaCredentials.path}"
    ];
  };

  # Docker (containers)
  virtualisation.docker.enable = true;

  # Secret manager (agenix)
  age = {
    secrets = {
      diskstationSambaCredentials.file =
        "${hostSecretsDir}/diskstationSambaCredentials.age";
      heraHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      heraNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      heraNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      heraResticHealthchecksUrl.file =
        "${hostSecretsDir}/resticHealthchecksUrl.age";
      heraResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      heraResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      heraResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [ ];

  # Keep laptop on when lid is closed
  services.logind.lidSwitch = "ignore";

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    email = "hera-lets-encrypt@diogotc.com";
    extraConfig = ''
      # Rules for services behind Cloudflare proxy
      (CLOUDFLARE_PROXY) {
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
      }
    '';
  };

  # PostgreSQL
  # services.postgresql.enable = true;

  # Modules
  modules = {
    editors.neovim.enable = true;
    server.enable = true;
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
          "/tmp/firefly_db.sql"
          "/tmp/nextcloud_db.sql"

          "${config.my.homeDirectory}/firefly-3"
          "${config.my.homeDirectory}/dailytxt"
          "${config.my.homeDirectory}/transmission-openvpn"
          "${config.my.homeDirectory}/grafana"
          "${config.my.homeDirectory}/jellyfin"
          "${config.my.homeDirectory}/calibre-web"
          "${config.my.homeDirectory}/ihatetobudget-joao"
          "${config.my.homeDirectory}/jellyfin"
        ];
        exclude = [
          "**/node_modules"
          "**/.npm"
          "${config.my.homeDirectory}/firefly-3/santander-crawler/.env"
          "${config.my.homeDirectory}/transmission-openvpn/data/completed"
          "${config.my.homeDirectory}/transmission-openvpn/data/incomplete"
        ];

        backupPrepareCommand = ''
          ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/firefly_db.sql
          ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/firefly-3/docker-compose.yml exec -T fireflyiiidb sh -c 'exec mysqldump --host=fireflyiiidb --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE' > /tmp/firefly_db.sql

          ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/nextcloud_db.sql
          ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/nextcloud/docker-compose.yml exec -T db sh -c 'exec mysqldump --host=db --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE' > /tmp/nextcloud_db.sql
        '';
        backupCleanupCommand = ''
          ${pkgs.coreutils}/bin/rm /tmp/firefly_db.sql
          ${pkgs.coreutils}/bin/rm /tmp/nextcloud_db.sql
        '';

        timerConfig = { OnCalendar = "03:05"; };
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
  system.stateVersion = "23.05";
}
