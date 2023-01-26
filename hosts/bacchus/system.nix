# hosts/bacchus/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# System configuration for bacchus (PC).

{ pkgs, lib, sshKeys, config, hostSecretsDir, user, agenixPackage, ... }: {

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.kernelParams = [ "nohibernate" ];
  networking.hostId = "239be557";
  zramSwap.enable = true;

  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "80%";

  environment.persistence."/persist" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/var/lib/libvirt"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };

  boot.cleanTmpDir = true;

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    kbdInteractiveAuthentication = false;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  modules.dnsovertls.enable = true;
  modules.dwm.enable = true;
  modules.ist.enable = true;
  modules.syncthing.enable = true;

  users = {
    mutableUsers = false;
    users = {
      ${user} = {
        initialPassword = "test";
        openssh.authorizedKeys.keys = sshKeys;
      };
    };
  };

  virtualisation.docker.enable = true;
}
