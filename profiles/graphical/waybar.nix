{ ... }:
{
  hm.programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      topbar = {
        layer = "top";
        position = "top";
        height = 29;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];

        modules-right = [
          "pulseaudio"
          "battery"
          "network"
          "clock"
        ];

        "niri/window" = {
          format = "{}";
          separate-outputs = true;
        };

        "niri/workspaces" = {
        };
      };
    };
  };
}
