# hosts/phobos/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for phobos (server).

{ pkgs, lib, sshKeys, config, hostSecretsDir, user, agenixPackage, ... }: {
  # Boot

  # /tmp configuration
  boot.cleanTmpDir = true;

  # Network Manager
  # TODO move to module

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    kbdInteractiveAuthentication = false;
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

  # Docker (containers)
  virtualisation.docker.enable = true;

  # Secret manager (agenix)
  age = {
    secrets = {
      phobosHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      phobosNebulaCert.file = "${hostSecretsDir}/nebulaCert.age";
      phobosNebulaKey.file = "${hostSecretsDir}/nebulaKey.age";
      phobosResticHealthchecksUrl.file =
        "${hostSecretsDir}/resticHealthchecksUrl.age";
      phobosResticRcloneConfig.file =
        "${hostSecretsDir}/resticRcloneConfig.age";
      phobosResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      phobosResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = [ "/root/.ssh/id_ed25519" ];

    # This VPS does not support an instruction used by the "rage" backend.
    # Therefore, use "age" instead.
    # See https://github.com/ryantm/agenix/pull/81
    ageBin = "${pkgs.age}/bin/age";
  };
  # See comment above about ageBin
  environment.systemPackages =
    [ (agenixPackage.override { ageBin = "${pkgs.age}/bin/age"; }) ];

  # Specific packages for this host
  hm.home.packages = with pkgs; [ ];

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    email = "phobos-lets-encrypt@diogotc.com";
    virtualHosts = {
      "healthchecks.diogotc.com" = {
        extraConfig = ''
          reverse_proxy localhost:8000
        '';
      };
      "uptime.diogotc.com" = {
        extraConfig = ''
          reverse_proxy localhost:8002
        '';
      };
    };
  };

  # Modules
  modules = {
    editors.neovim.enable = true;
    services = {
      dnsovertls.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosHealthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.phobosNebulaCert.path;
        key = config.age.secrets.phobosNebulaKey.path;
      };
      restic = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.phobosResticRcloneConfig.path;
        passwordFile = config.age.secrets.phobosResticPassword.path;
        sshKeyFile = config.age.secrets.phobosResticSshKey.path;

        paths = [
          "${config.my.homeDirectory}/uptime-kuma"
          "${config.my.homeDirectory}/healthchecks/docker/.env"
          "/tmp/healthchecks_db.sql"
        ];
        backupPrepareCommand = ''
          ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/healthchecks_db.sql
          ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/healthchecks/docker/docker-compose.yml exec -T db sh -c 'PGPASSWORD=$POSTGRES_PASSWORD exec pg_dump --format=custom --username postgres $POSTGRES_DB' > /tmp/healthchecks_db.sql
        '';
        backupCleanupCommand = ''
          ${pkgs.coreutils}/bin/rm /tmp/healthchecks_db.sql
        '';

        timerConfig = { OnCalendar = "03:10"; };
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
