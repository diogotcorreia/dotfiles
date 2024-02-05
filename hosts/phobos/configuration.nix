# hosts/phobos/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for phobos (server).
{
  pkgs,
  lib,
  sshKeys,
  config,
  hostSecretsDir,
  agenixPackage,
  ...
}: {
  # Boot

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Network Configuration
  # Configure static IPv6 address
  networking = {
    interfaces = {
      ens3.ipv6.addresses = [
        {
          address = "2a03:4000:2a:1b3::";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
  };

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

  # Secret manager (agenix)
  age = {
    secrets = {
      phobosAutoUpgradeHealthchecksUrl.file = "${hostSecretsDir}/autoUpgradeHealthchecksUrl.age";
      phobosHealthchecksUrl.file = "${hostSecretsDir}/healthchecksUrl.age";
      phobosNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      phobosNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      phobosResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      phobosResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      phobosResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      phobosResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/root/.ssh/id_ed25519"];

    # This VPS does not support an instruction used by the "rage" backend.
    # Therefore, use "age" instead.
    # See https://github.com/ryantm/agenix/pull/81
    ageBin = "${pkgs.age}/bin/age";
  };
  # See comment above about ageBin
  environment.systemPackages = [(agenixPackage.override {ageBin = "${pkgs.age}/bin/age";})];

  # Specific packages for this host
  hm.home.packages = with pkgs; [];

  # Caddy (web server)
  networking.firewall.allowedTCPPorts = [80 443];
  services.caddy = {
    enable = true;
    email = "phobos-lets-encrypt@diogotc.com";
  };

  # PostgreSQL
  services.postgresql.enable = true;

  # Modules
  modules = {
    editors.neovim.enable = true;
    server = {
      enable = true;
      autoUpgradeCheckUrlFile =
        config.age.secrets.phobosAutoUpgradeHealthchecksUrl.path;
    };
    services = {
      dnsoverhttps.enable = true;
      healthchecks = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosHealthchecksUrl.path;
      };
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.phobosNebulaCert.path;
        key = config.age.secrets.phobosNebulaKey.path;
        isLighthouse = true;
      };
      restic = {
        enable = true;
        checkUrlFile = config.age.secrets.phobosResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.phobosResticRcloneConfig.path;
        passwordFile = config.age.secrets.phobosResticPassword.path;
        sshKeyFile = config.age.secrets.phobosResticSshKey.path;

        timerConfig = {OnCalendar = "03:10";};
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
