# modules/graphical/xournalpp.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Xournal++ configuration

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.xournalpp;
in {
  options.modules.graphical.xournalpp.enable =
    mkEnableOption "xournal++ with custom toolbar";

  config = mkIf cfg.enable {
    hm.home.packages = [ pkgs.unstable.xournalpp ];

    hm.xdg.configFile."xournalpp/colornames.ini" = {
      text = ''
        [info]
        about=Xournalpp custom color names

        [custom]
        0c0c0c=Dark Gray
      '';
      force = true;
    };

    hm.xdg.configFile."xournalpp/toolbar.ini" = {
      text = ''
        [DTC Toolbar]
        toolbarTop1=SAVE,NEW,OPEN,SEPARATOR,CUT,COPY,PASTE,SEPARATOR,UNDO,REDO,SEPARATOR,PEN,ERASER,HIGHLIGHTER,IMAGE,TEXT,MATH_TEX,DRAW,SEPARATOR,SELECT,VERTICAL_SPACE,HAND,SEPARATOR,FINE,MEDIUM,THICK,SEPARATOR,TOOL_FILL,SEPARATOR,COLOR(0xf5f749),COLOR(0xffa400),COLOR(0xe4805a),COLOR(0xf5736a),COLOR(0xe5989b),COLOR(0xd979ca),COLOR(0xc4f1be),COLOR(0x81a486),COLOR(0x819cce),COLOR(0x45a5cd),COLOR(0xa5a5a5),COLOR(0xffffff),COLOR_SELECT,SEPARATOR,SELECT_FONT
        toolbarBottom1=PAGE_SPIN,SEPARATOR,LAYER,GOTO_FIRST,GOTO_NEXT_ANNOTATED_PAGE,GOTO_LAST,INSERT_NEW_PAGE,DELETE_CURRENT_PAGE,SPACER,PAIRED_PAGES,PRESENTATION_MODE,ZOOM_100,ZOOM_FIT,ZOOM_OUT,ZOOM_SLIDER,ZOOM_IN,SEPARATOR,FULLSCREEN
        name=DTC Toolbar
      '';
      force = true;
    };
  };
}
