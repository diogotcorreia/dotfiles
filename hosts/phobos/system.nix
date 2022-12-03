# hosts/phobos/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# System configuration for phobos (server).

{ pkgs, lib, sshKeys, config, hostSecretsDir, user, agenixPackage, ... }: {
  boot.cleanTmpDir = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    kbdInteractiveAuthentication = false;
  };

  users = {
    mutableUsers = true;
    users = { ${user}.openssh.authorizedKeys.keys = sshKeys; };
  };

  virtualisation.docker.enable = true;

  # Secret manager
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

  environment.systemPackages =
    [ (agenixPackage.override { ageBin = "${pkgs.age}/bin/age"; }) ];

  modules.healthchecks = {
    enable = true;
    checkUrlFile = config.age.secrets.phobosHealthchecksUrl.path;
  };

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

  modules.nebula = {
    enable = true;
    cert = config.age.secrets.phobosNebulaCert.path;
    key = config.age.secrets.phobosNebulaKey.path;
  };

  modules.restic = {
    enable = true;
    checkUrlFile = config.age.secrets.phobosResticHealthchecksUrl.path;
    rcloneConfigFile = config.age.secrets.phobosResticRcloneConfig.path;
    passwordFile = config.age.secrets.phobosResticPassword.path;
    sshKeyFile = config.age.secrets.phobosResticSshKey.path;

    paths = [
      "/home/${user}/uptime-kuma"
      "/home/${user}/healthchecks/docker/.env"
      "/tmp/healthchecks_db.sql"
    ];
    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/healthchecks_db.sql
      ${pkgs.docker}/bin/docker compose -f /home/${user}/healthchecks/docker/docker-compose.yml exec -T db sh -c 'PGPASSWORD=$POSTGRES_PASSWORD exec pg_dump --format=custom --username postgres $POSTGRES_DB' > /tmp/healthchecks_db.sql
    '';
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm /tmp/healthchecks_db.sql
    '';

    timerConfig = { OnCalendar = "03:10"; };
  };

}
