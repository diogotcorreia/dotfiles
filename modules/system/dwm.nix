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
    environment.systemPackages = with pkgs; [
      alacritty
      dmenu
      (dwmblocks.overrideAttrs (old: rec {
        src = fetchFromGitHub {
          owner = "LukeSmithxyz";
          repo = "dwmblocks";
          rev = "5a6fa8d550c11552480f10e660073ca294d446b1";
          sha256 = "1fkc094vhb3x58zy2k8n66xsjrlmzdi70fc4d2l0y5hq1jwsvnyx";
        };
      }))
    ];

    fonts.fonts = with pkgs; [ fira-code material-design-icons ];

    services.xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "altgr-intl";
      autorun = true;
      displayManager.startx.enable = true;
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
