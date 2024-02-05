# modules/graphical/zathura.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# PDF viewer
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.modules.graphical.programs;
in {
  # Follow graphical.programs.enable
  config.hm = mkIf cfg.enable {
    programs.zathura = {
      enable = true;
      options = {
        selection-clipboard = "clipboard";
        recolor = "true"; # open documents with inverted colors by default
        sandbox = "none"; # fix links not opening on browser
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Use Zathura as default PDF viewer
        "application/pdf" = ["org.pwmt.zathura.desktop"];
      };
    };
  };
}
