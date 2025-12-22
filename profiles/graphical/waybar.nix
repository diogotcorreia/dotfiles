{ pkgs, lib, ... }:
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
          "custom/dunst"
          "memory"
          "cpu"
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

        "custom/dunst" = {
          exec = pkgs.writeShellScript "dunst-waybar.sh" ''
            set -euo pipefail

            readonly ENABLED='󰂚'
            readonly DISABLED='󰂛'
            dbus-monitor path='/org/freedesktop/Notifications',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged' --profile |
              while read -r _; do
                PAUSED="$(dunstctl is-paused)"
                if [ "$PAUSED" == 'false' ]; then
                  CLASS="enabled"
                  TEXT="$ENABLED"
                else
                  CLASS="disabled"
                  TEXT="$DISABLED"
                  COUNT="$(dunstctl count waiting)"
                  if [ "$COUNT" != '0' ]; then
                    TEXT="$DISABLED ($COUNT)"
                  fi
                fi
                printf '{"text": "%s", "class": "%s"}\n' "$TEXT" "$CLASS"
              done
          '';
          return-type = "json";
          restart-interval = 5;
          on-click = "dunstctl set-paused toggle";
        };

        memory = {
          format = "󰘚 {used:0.2f}GiB/{total:0.2f}GiB";
          on-click = lib.my.mkTui "htop";
        };

        cpu = {
          # TODO: scale cpu cores automatically
          # https://github.com/Alexays/Waybar/issues/4240
          format = "󰍛 ${lib.concatMapStrings (n: "{icon${toString n}}") (lib.range 0 7)}";
          format-icons = [
            "▁"
            "▂"
            "▃"
            "▄"
            "▅"
            "▆"
            "▇"
            "█"
            "█"
          ];
          on-click = lib.my.mkTui "htop";
        };

        pulseaudio = {
          format = "{format_source} {icon} {volume}%";
          format-bluetooth = "{format_source} {icon} {volume}% 󰂰 {desc}";
          format-muted = "{format_source} 󰝟";
          format-source = "󰍬 {volume}%";
          format-source-muted = "󰍭";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = lib.my.mkTui "pulsemixer";
          reverse-scrolling = true;
        };

        battery = {
          states = {
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-icons = {
            full = "󱟢";
            charging = "󰚥";
            plugged = "󰏧";
            discharging = [
              "󰁺"
              "󰁻"
              "󰁾"
              "󰂀"
              "󰁹"
            ];
            discharging-critical = "󰀦󰁺";
            default = "󰂑";
          };
        };

        network = {
          format-wifi = "{icon} {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          format-icons = {
            wifi = [
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
          };
          tooltip-format-wifi = "{essid} ({ifname})";
          on-click = lib.my.mkTui "nmtui";
        };

        clock = {
          format = "󱑆  {:%Y %b %d (%a) %H:%M:%S}";
          interval = 1;
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              # TODO: use nord colors
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
          };
        };
      };
    };
  };
}
