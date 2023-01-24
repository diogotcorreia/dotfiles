# modules/home/graphical/brave.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# configuration for personal computers.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.brave;
in {
  options.modules.graphical.brave.enable = mkEnableOption "brave";

  config = mkIf cfg.enable {

    programs.brave.enable = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Set Brave as default browser
        "text/html" = [ "brave-browser.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/about" = [ "brave-browser.desktop" ];
        "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
      };
    };
  };
}
