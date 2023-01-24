# hosts/bacchus/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# System configuration for bacchus (PC).

{ pkgs, lib, sshKeys, config, hostSecretsDir, user, agenixPackage, ... }: {

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.cleanTmpDir = true;

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    kbdInteractiveAuthentication = false;
  };

  modules.dwm.enable = true;
  modules.ist.enable = true;
  modules.syncthing.enable = true;

  users = {
    mutableUsers = true;
    users = { ${user}.openssh.authorizedKeys.keys = sshKeys; };
  };

  virtualisation.docker.enable = true;
}
