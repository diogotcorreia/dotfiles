# modules/graphical/brave.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Brave web browser configuration

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.programs;
in {
  # Follow graphical.programs.enabled
  config.hm = mkIf cfg.enable {

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
