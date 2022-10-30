# hosts/phobos/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# System configuration for phobos (server).

{ pkgs, lib, sshKeys, ... }: {

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

  virtualisation.docker = {
    enable = true;
  };

}
