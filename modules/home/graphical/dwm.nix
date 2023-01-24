# modules/home/graphical/dwm.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# DWM window manager user configuration

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.dwm;
in {
  options.modules.graphical.dwm.enable = mkEnableOption "dwm";

  config = mkIf cfg.enable (let
    # colors
    # TODO use colors from flake.nix
    black = "#2E3440";
    white = "#D8DEE9";
    grey = "#373d49";
    blue = "#81A1C1";
    darkblue = "#7292b2";
    red = "#BF616A";
    orange = "#D08770";
    yellow = "#EBCB8B";
    green = "#A3BE8C";
    pink = "#B48EAD";

    # Mapping of MDI icon names to unicode codepoint:
    # https://cdn.jsdelivr.net/npm/@mdi/svg@6.9.96/meta.json
    statusbarModules = [
      (pkgs.writeScriptBin "sb-clock" ''
        #! /usr/bin/env sh

        printf "^c${black}^^b${darkblue}^ 󱑆 "
        printf "^c${black}^^b${blue}^ $(date '+%Y %b %d (%a) %H:%M:%S') "
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
    ];

    sbPath =
      lib.strings.concatMapStringsSep ":" (x: "${x}/bin") statusbarModules;
  in {
    home.file.".xinitrc".text = ''
      #! /usr/bin/env sh

      PATH="$PATH:${sbPath}"

      dwmblocks &
      while type dwm >/dev/null; do dwm && continue || break; done
    '';
  });
}
