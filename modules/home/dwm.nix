# modules/home/dwm.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# DWM window manager user configuration

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.dwm;
in {
  options.modules.dwm.enable = mkEnableOption "dwm";

  config = mkIf cfg.enable (let
    sbClockScript = pkgs.writeScriptBin "sb-clock" ''
      #! /usr/bin/env sh

      # colors
      black=#2E3440
      green=#A3BE8C
      white=#D8DEE9
      grey=#373d49
      blue=#81A1C1
      red=#BF616A
      darkblue=#7292b2

      printf "^c$black^ ^b$darkblue^ 󱑆 "
      printf "^c$black^^b$blue^ $(date '+%Y %b %d (%a) %H:%M:%S')  "
    '';
  in {
    home.file.".xinitrc".text = ''
      #! /usr/bin/env sh

      PATH="$PATH:${sbClockScript}/bin"

      dwmblocks &
      while type dwm >/dev/null; do dwm && continue || break; done
    '';
  });
}
