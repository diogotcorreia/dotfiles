# modules/graphical/firefox.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Firefox web browser configuration

{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.modules.graphical.programs;
in {
  # Follow graphical.programs.enabled
  config.hm = mkIf cfg.enable {

    programs.firefox.enable = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Set Firefox as default browser
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      };
    };
  };
}
