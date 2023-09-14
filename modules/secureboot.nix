# modules/secureboot.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Secure Boot configuration
# https://github.com/nix-community/lanzaboote/

{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.secureboot;

  securebootFolder = "/etc/secureboot/";
in {
  options.modules.secureboot.enable =
    mkEnableOption "secureboot with lanzaboote";

  config = mkIf cfg.enable {
    boot.bootspec.enable = true;
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = securebootFolder;
    };
    modules.impermanence.directories = [ securebootFolder ];

    environment.systemPackages = [
      # For debugging and troubleshooting Secure Boot.
      pkgs.sbctl
    ];
  };
}
