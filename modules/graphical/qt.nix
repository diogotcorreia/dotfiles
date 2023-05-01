# modules/graphical/qt.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Qt theme configuration

{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.qt;
in {
  options.modules.graphical.qt.enable = mkEnableOption "qt";

  config = mkIf cfg.enable {
    modules.graphical.gtk.enable = true;
    hm.qt = {
      enable = true;
      platformTheme = "gtk";
    };
  };
}
