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
          format = "{format_source}   {icon} {volume}%";
          format-bluetooth = "{format_source}   {icon} {volume}% 󰂰 {desc}";
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
            half = 50;
            low = 25;
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
            format = with lib.my.colors; {
              months = "<span color='${yellow}'><b>{}</b></span>";
              days = "<span color='${pink}'><b>{}</b></span>";
              weeks = "<span color='${lightblue}'><b>W{}</b></span>";
              weekdays = "<span color='${orange}'><b>{}</b></span>";
              today = "<span color='${red}'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
          };
        };
      };
    };

    style = with lib.my.colors; ''
      @define-color black ${black};
      @define-color darkgrey ${darkgrey};
      @define-color grey ${grey};
      @define-color lightgrey ${lightgrey};
      @define-color darkwhite ${darkwhite};
      @define-color white ${white};
      @define-color lightwhite ${lightwhite};
      @define-color teal ${teal};
      @define-color lightblue ${lightblue};
      @define-color blue ${blue};
      @define-color darkblue ${darkblue};
      @define-color red ${red};
      @define-color orange ${orange};
      @define-color yellow ${yellow};
      @define-color green ${green};
      @define-color pink ${pink};

      * {
        font-family: 'Material Design Icons', 'Fira Code', monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: @black;
        color: @lightwhite;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      button {
        border: none;
        border-radius: 0;
      }

      #workspaces button {
        padding: 0;
        margin: 0 5px;
        background-color: transparent;
        font-weight: bold;
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }

      #workspaces button:nth-child(5n+1).focused, #workspaces button:nth-child(5n+1).active {
        color: @blue;
        box-shadow: inset 0 -3px @blue;
      }
      #workspaces button:nth-child(5n+2).focused, #workspaces button:nth-child(5n+2).active {
        color: @red;
        box-shadow: inset 0 -3px @red;
      }
      #workspaces button:nth-child(5n+3).focused, #workspaces button:nth-child(5n+3).active {
        color: @yellow;
        box-shadow: inset 0 -3px @yellow;
      }
      #workspaces button:nth-child(5n+4).focused, #workspaces button:nth-child(5n+4).active {
        color: @green;
        box-shadow: inset 0 -3px @green;
      }
      #workspaces button:nth-child(5n+5).focused, #workspaces button:nth-child(5n+5).active {
        color: @pink;
        box-shadow: inset 0 -3px @pink;
      }

      #workspaces button.urgent {
        background-color: @red;
      }

      #window {
        padding: 0 10px;
      }

      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #custom-dunst {
        padding: 0 5px;
      }

      #clock {
        color: @black;
        background-color: @blue;
        margin: 4px;
        padding: 1px 5px 0 5px;
      }

      #network {
        color: @orange;
      }

      #battery {
        color: @green;
      }

      #battery.charging {
        color: @blue;
      }

      #battery.low {
        color: @orange;
      }

      #battery.half {
        color: @yellow;
      }

      @keyframes blink {
        to {
          background-color: @black;
        }
      }

      /* Using steps() instead of linear as a timing function to limit cpu usage */
      #battery.critical:not(.charging) {
        background-color: @red;
        color: @white;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #pulseaudio {
        color: @yellow;
      }

      #cpu {
        color: @red;
      }

      #memory {
        color: @green;
      }

      #custom-dunst {
        color: @yellow;
      }
    '';
  };
}
