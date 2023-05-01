# modules/graphical/dwm.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# DWM window manager and graphical environment configuration

{ pkgs, config, lib, configDir, user, colors, ... }:
let
  inherit (lib) mkEnableOption mkIf escapeShellArg;
  cfg = config.modules.graphical;
in {
  config = mkIf cfg.enable (let
    # colors
    inherit (colors)
      black white grey blue darkblue red orange yellow green pink;

    # To type UTF-8 codepoints into vim: in insert mode, Ctrl + V, U<codepoint><ESC>
    # Alternatively, copy glyph from MDI website
    statusbarModules = [
      (pkgs.writeScriptBin "sb-clock" ''
        #! /usr/bin/env sh

        printf "^c${black}^^b${darkblue}^ 󱑆 "
        printf "^c${black}^^b${blue}^ $(date '+%Y %b %d (%a) %H:%M:%S') "
      '')
      (pkgs.writeScriptBin "sb-internet" ''
        #! /usr/bin/env sh

        # Show wifi 󰤨 and percent strength or 󰤭 if none.
        # Show 󰈀 if connected to ethernet or 󰅛 if none.
        # Show 󰌆 if a vpn connection is active

        case "$(cat /sys/class/net/w*/operstate 2>/dev/null)" in
          down) wifiicon="󰤭 " ;;
          up) wifiicon="$(awk '/^\s*w/ { print "󰤨 ", int($3 * 100 / 70) "% " }' /proc/net/wireless)" ;;
        esac

        printf "^c${orange}^%s%s%s^d^" "$wifiicon" "$(sed "s/down/󰅛/;s/up/󰈀/" /sys/class/net/e*/operstate 2>/dev/null)" "$(sed "s/.*/ 󰌆/" /sys/class/net/tun*/operstate 2>/dev/null)"
      '')
      (pkgs.writeScriptBin "sb-battery" ''
        #! /usr/bin/env sh

        # Don't do anything if the computer doesn't have a battery
        [ ! -e /sys/class/power_supply/BAT0 ] && exit 0

        for battery in /sys/class/power_supply/BAT?*; do
          # If non-first battery, print a space separator.
          [ -n "''${capacity+x}" ] && printf " "
          # Sets up the status and capacity
          case "$(cat "$battery/status")" in
            "Full") status="󱟢" ;;
            "Discharging") status="󰁹" ;;
            "Charging") status="󰚥" && color="${blue}" ;;
            "Not charging") status="󰏧" ;;
            "Unknown") status="󰂑" ;;
          esac
          capacity=$(cat "$battery/capacity")
          color="${green}"
          # Will make a warn variable if discharging and low
          [ "$status" = "󰁹" ] && [ "$capacity" -le 10 ] && warn="󰀦"
          [ "$status" = "󰁹" ] && [ "$capacity" -le 10 ] && status="󰁺" && color="${red}"
          [ "$status" = "󰁹" ] && [ "$capacity" -le 25 ] && status="󰁻" && color="${orange}"
          [ "$status" = "󰁹" ] && [ "$capacity" -le 50 ] && status="󰁾" && color="${yellow}"
          [ "$status" = "󰁹" ] && [ "$capacity" -le 75 ] && status="󰂀"
          # Prints the info
          printf "^c%s^%s%s %d%%" "$color" "$status" "$warn" "$capacity"; unset warn
        done && exit 0
      '')
      (pkgs.writeScriptBin "sb-sound" ''
        #! /usr/bin/env sh

        printf "^c${yellow}^"

        # Check if microphone is muted
        # https://stackoverflow.com/a/35165216
        if [ $(${pkgs.pulsemixer}/bin/pulsemixer --list-sources | grep Default | grep "Mute: 1" | head -c1 | wc -c) -ne 0 ]; then
          printf "󰍭 "
        fi

        # Check if sound output is muted
        muted="$(${pkgs.pulsemixer}/bin/pulsemixer --get-mute)"
        if [ $muted -eq '1' ]; then
          printf "󰝟"
        else
          # Get current volume from pulsemixer
          volume="$(${pkgs.pulsemixer}/bin/pulsemixer --get-volume)"
          # Split into left and right channels
          # https://stackoverflow.com/a/2440602
          IFS=" "
          set -- $volume
          volumeleft=$1
          volumeright=$2

          if [ $volumeleft -lt 30 ]; then
            printf "󰕿 "
          elif [ $volumeleft -lt 60 ]; then
            printf "󰖀 "
          else
            printf "󰕾 "
          fi

          # Only show one channel if they are the same, otherwise show both
          if [ $volumeleft -eq $volumeright ]; then
            printf "%d%%" "$volumeleft"
          else
            printf "L: %d%% R: %d%%" "$volumeleft" "$volumeright"
          fi
        fi
      '')
      (pkgs.writeScriptBin "sb-nettraf" ''
        #! /usr/bin/env sh

        # Module showing network traffic. Shows how much data has been received (RX) or
        # transmitted (TX) since the previous time this script ran. So if run every
        # second, gives network traffic per second.

        update() {
            sum=0
            for arg; do
                read -r i < "$arg"
                sum=$(( sum + i ))
            done
            cache=/tmp/''${1##*/}
            [ -f "$cache" ] && read -r old < "$cache" || old=0
            printf %d\\n "$sum" > "$cache"
            printf %d\\n $(( sum - old ))
        }

        rx=$(update /sys/class/net/[ew]*/statistics/rx_bytes)
        tx=$(update /sys/class/net/[ew]*/statistics/tx_bytes)

        printf "^c${pink}^󰁆%4sB 󰁞%4sB^d^\\n" $(numfmt --to=iec $rx) $(numfmt --to=iec $tx)
      '')
      (pkgs.writeScriptBin "sb-cpubars" ''
        #! /usr/bin/env sh

        # Module showing CPU load as a changing bars.
        # Each bar represents amount of load on one core since
        # last run.

        # Cache in tmpfs to improve speed and reduce SSD load
        cache=/tmp/cpubarscache

        # id total idle
        stats=$(awk '/cpu[0-9]+/ {printf "%d %d %d\n", substr($1,4), ($2 + $3 + $4 + $5), $5 }' /proc/stat)
        [ ! -f $cache ] && echo "$stats" > "$cache"
        old=$(cat "$cache")
        printf "^c${red}^󰍛 "
        echo "$stats" | while read -r row; do
          id=''${row%% *}
          rest=''${row#* }
          total=''${rest%% *}
          idle=''${rest##* }

          case "$(echo "$old" | awk '{if ($1 == id)
            printf "%d\n", (1 - (idle - $3)  / (total - $2))*100 /12.5}' \
            id="$id" total="$total" idle="$idle")" in

            "0") printf "▁";;
            "1") printf "▂";;
            "2") printf "▃";;
            "3") printf "▄";;
            "4") printf "▅";;
            "5") printf "▆";;
            "6") printf "▇";;
            "7") printf "█";;
            "8") printf "█";;
          esac
        done; printf "^d^"
        echo "$stats" > "$cache"
      '')
      (pkgs.writeScriptBin "sb-memory" ''
        #! /usr/bin/env sh

        free --mebi | sed -n '2{p;q}' | awk '{printf ("^c${green}^󰘚 %2.2fGiB/%2.2fGiB^d^", ( $3 / 1024), ($2 / 1024))}'
      '')
      (pkgs.writeScriptBin "sb-timewarrior" ''
        #! /usr/bin/env sh

        # Prints whether or not there is current timetracking with timewarrior.

        current_tracking="$(timew | head -n 1)"
        if [ "$current_tracking" = "There is no active time tracking." ]; then
          icon="󰚭"
        else
          icon="󱦟 $(echo $current_tracking | cut -c 10-)"
        fi

        echo -n "^c${blue}^$icon^d^"
      '')
      (pkgs.writeScriptBin "sb-dunst-pause" ''
        #! /usr/bin/env sh

        # Module showing if dunst is paused and if so, how many notifications are pending
        # Icon is ommited if not paused

        OUT=""

        if [ "$(dunstctl is-paused)" = "true" ]; then
          OUT="󰂛"
          WAITING="$(dunstctl count waiting)"
          if [ $WAITING != 0 ]; then
            OUT="$OUT ($WAITING)"
          fi
        fi

        echo "^c${yellow}^$OUT^d^"
      '')
      (pkgs.writeScriptBin "toggle-dunst-notifications" ''
        #! /usr/bin/env sh

        # Wrapper to toggle dunst 'set-pause' and send signal to dwmblocks to reload widget

        dunstctl set-paused toggle && pkill -RTMIN+19 dwmblocks
      '')
    ];

    sbPath =
      lib.strings.concatMapStringsSep ":" (x: "${x}/bin") statusbarModules;
  in {
    environment.systemPackages = with pkgs;
      [
        (dwmblocks.overrideAttrs (old: rec {
          src = fetchFromGitHub {
            owner = "LukeSmithxyz";
            repo = "dwmblocks";
            rev = "5a6fa8d550c11552480f10e660073ca294d446b1";
            sha256 = "1fkc094vhb3x58zy2k8n66xsjrlmzdi70fc4d2l0y5hq1jwsvnyx";
          };
        }))
      ];

    fonts.fonts = with pkgs; [ material-design-icons ];

    hm.xsession = {
      initExtra = ''
        PATH="$PATH:${sbPath}"

        # Statusbar
        dwmblocks &
      '';
    };

  });
}
