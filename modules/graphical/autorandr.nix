# modules/graphical/autorandr.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Autorandr configuration for laptops
{
  config,
  lib,
  ...
}: let
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
          fingerprint = {"eDP1" = "*";};
          config = {
            eDP1 = {
              enable = true;
              primary = true;
              mode = "1920x1080";
              position = "0x0";
              rotate = "normal";
              dpi = 96;
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
              dpi = 96;
            };
          };
        };
        # Dual monitor profile: HDMI on top of eDP (but 16:10 aspect ratio)
        alt-laptop-dual = {
          fingerprint = {
            "eDP1" = "*";
            "HDMI1" = "00ffffffffffff0010ac79a0554130331c1b010380342078eaee95a3544c99260f5054a1080081408180a940b300d1c0010101010101283c80a070b023403020360006442100001a000000ff005950505930373743333041550a000000fc0044454c4c2055323431324d0a20000000fd00323d1e5311000a2020202020200020";
          };
          config = {
            HDMI1 = {
              enable = true;
              primary = false;
              mode = "1920x1200";
              position = "0x0";
              rotate = "normal";
              dpi = 144;
            };
            eDP1 = {
              enable = true;
              primary = true;
              mode = "1920x1080";
              position = "0x1200";
              rotate = "normal";
              dpi = 96;
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
