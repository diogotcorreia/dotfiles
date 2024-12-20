{
  lib,
  pkgs,
  ...
}: let
  securebootFolder = "/etc/secureboot/";
in {
  boot.bootspec.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = securebootFolder;
  };
  modules.impermanence.directories = [securebootFolder];

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];
}
