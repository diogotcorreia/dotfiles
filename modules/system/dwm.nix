# modules/system/dwm.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# dwm window manager configuration

{ pkgs, config, lib, utils, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  inherit (lib.strings) optionalString;
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.modules.dwm;
in {
  options.modules.dwm = { enable = mkEnableOption "dwm"; };

  config = mkIf cfg.enable {

    programs.slock.enable = true;
    environment.systemPackages = with pkgs; [ alacritty dmenu flameshot ];

    services.xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "altgr-intl";
      autorun = true;
      displayManager = {
        defaultSession = "none+dwm";
        lightdm.enable = true; # TODO use startx instead
      };
      windowManager = { dwm.enable = true; };
      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          naturalScrolling = true;
        };
      };
    };

  };
}
