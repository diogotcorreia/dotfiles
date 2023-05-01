# modules/graphical/autorandr.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Autorandr configuration for laptops

{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.autorandr;
in {
  options.modules.graphical.autorandr.laptop.enable =
    mkEnableOption "autorandr laptop configuration";

  config = mkIf cfg.laptop.enable {
    services.autorandr = {
      enable = true;
      defaultTarget = "laptop";
      profiles = {
        laptop = {
          fingerprint = { "eDP1" = "*"; };
          config = {
            eDP1 = {
              enable = true;
              primary = true;
              mode = "1920x1080";
              position = "0x0";
              rotate = "normal";
            };
          };
        };
        # Dual monitor profile: HDMI on top of eDP
        laptop-dual = {
          fingerprint = {
            "eDP1" = "*";
            "HDMI1" = "*";
          };
          config = {
            HDMI1 = {
              enable = true;
              primary = false;
              mode = "1920x1080";
              position = "0x0";
              rotate = "normal";
            };
            eDP1 = {
              enable = true;
              primary = true;
              mode = "1920x1080";
              position = "0x1080";
              rotate = "normal";
            };
          };
        };
      };
      hooks = {
        postswitch = {
          "set-wallpaper" = "systemctl --user start set-wallpaper";
          "update-sound-dwmblocks-widget" = "pkill -RTMIN+10 dwmblocks";
        };
      };
    };
  };
}
