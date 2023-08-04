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
  # TODO Configure static IPv4 address
  networking.useDHCP = true;

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

  # Secret manager (agenix)
  age = {
    secrets = {
      diskstationSambaCredentials.file =
        "${hostSecretsDir}/diskstationSambaCredentials.age";
      # heraHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      # heraNebulaCert = {
      # file = "${hostSecretsDir}/nebulaCert.age";
      # owner = "nebula-nebula0";
      # };
      # heraNebulaKey = {
      # file = "${hostSecretsDir}/nebulaKey.age";
      # owner = "nebula-nebula0";
      # };
      # heraResticHealthchecksUrl.file =
      # "${hostSecretsDir}/resticHealthchecksUrl.age";
      # heraResticRcloneConfig.file =
      # "${hostSecretsDir}/resticRcloneConfig.age";
      # heraResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      # heraResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [ ];

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    email = "hera-lets-encrypt@diogotc.com";
  };

  # PostgreSQL
  # services.postgresql.enable = true;

  # Modules
  modules = {
    editors.neovim.enable = true;
    server.enable = true;
    services = {
      dnsoverhttps.enable = true;
      # healthchecks = {
      # enable = true;
      # checkUrlFile = config.age.secrets.heraHealthchecksUrl.path;
      # };
      # Nebula (VPN)
      # nebula = {
      # enable = true;
      # cert = config.age.secrets.heraNebulaCert.path;
      # key = config.age.secrets.heraNebulaKey.path;
      # };
      # restic = {
      # enable = true;
      # checkUrlFile = config.age.secrets.heraResticHealthchecksUrl.path;
      # rcloneConfigFile = config.age.secrets.heraResticRcloneConfig.path;
      # passwordFile = config.age.secrets.heraResticPassword.path;
      # sshKeyFile = config.age.secrets.heraResticSshKey.path;

      # timerConfig = { OnCalendar = "03:10"; };
      # };
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
