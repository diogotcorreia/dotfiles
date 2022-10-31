# hosts/phobos/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# System configuration for phobos (server).

{ pkgs, lib, sshKeys, config, ... }: {
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
    users = {
      # TODO derive user from flake.nix
      dtc.openssh.authorizedKeys.keys = sshKeys;
    };
  };

  virtualisation.docker.enable = true;

  # Secret manager
  age = {
    secrets = {
      phobosHealthchecksUrl.file = ../../secrets/phobosHealthchecksUrl.age;
    };

    identityPaths = [ "/root/.ssh/id_ed25519" ];

    # This VPS does not support an instruction used by the "rage" backend.
    # Therefore, use "age" instead.
    # See https://github.com/ryantm/agenix/pull/81
    ageBin = "${pkgs.age}/bin/age";
  };

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

}
