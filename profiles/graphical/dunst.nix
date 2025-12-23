# Configuration for dunst (notification daemon)
{ lib, ... }:
{
  hm.services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Fira Code";
        markup = true;
        alignment = "center";
        line_height = 3;
        padding = 6;
        horizontal_padding = 6;
        max_icon_size = 80;

        frame_color = lib.my.colors.green;
        background = lib.my.colors.black;
        foreground = lib.my.colors.lightwhite;

        idle_timeout = 30;

        dmenu = "fuzzel --dmenu";
      };

      urgency_low = {
        frame_color = lib.my.colors.lightblue;
      };

      urgency_normal = {
        frame_color = lib.my.colors.green;
      };

      urgency_critical = {
        frame_color = lib.my.colors.red;
      };
    };
  };
}
