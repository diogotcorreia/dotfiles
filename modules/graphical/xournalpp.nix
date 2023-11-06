# modules/graphical/xournalpp.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Xournal++ configuration

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf strings;
  inherit (strings) concatStringsSep;
  cfg = config.modules.graphical.xournalpp;

  toolbar = {
    name = "DTC Toolbar";
    top = [
      "SAVE"
      "NEW"
      "OPEN"
      "SEPARATOR"
      "SAVEPDF"
      "PRINT"
      "SEPARATOR"
      "CUT"
      "COPY"
      "PASTE"
      "SEPARATOR"
      "UNDO"
      "REDO"
      "SEPARATOR"
      "PEN"
      "ERASER"
      "HIGHLIGHTER"
      "PDF_TOOL"
      "IMAGE"
      "TEXT"
      "MATH_TEX"
      "DRAW"
      "SEPARATOR"
      "SELECT"
      "VERTICAL_SPACE"
      "HAND"
      "SETSQUARE"
      "COMPASS"
      "SEPARATOR"
      "FINE"
      "MEDIUM"
      "THICK"
      "SEPARATOR"
      "TOOL_FILL"
      "SEPARATOR"
      "COLOR(11)"
      "COLOR(12)"
      "COLOR(13)"
      "COLOR(14)"
      "COLOR(15)"
      "COLOR(16)"
      "COLOR(17)"
      "COLOR(18)"
      "COLOR(19)"
      "COLOR(20)"
      "COLOR(21)"
      "COLOR(10)"
      "COLOR_SELECT"
      "SEPARATOR"
      "SELECT_FONT"
    ];

    bottom = [
      "PAGE_SPIN"
      "SEPARATOR"
      "LAYER"
      "GOTO_FIRST"
      "GOTO_NEXT_ANNOTATED_PAGE"
      "GOTO_LAST"
      "INSERT_NEW_PAGE"
      "DELETE_CURRENT_PAGE"
      "SPACER"
      "PAIRED_PAGES"
      "PRESENTATION_MODE"
      "ZOOM_100"
      "ZOOM_FIT"
      "ZOOM_OUT"
      "ZOOM_SLIDER"
      "ZOOM_IN"
      "SEPARATOR"
      "FULLSCREEN"
    ];
  };
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

    hm.xdg.configFile."xournalpp/palette.gpl" = {
      text = ''
        GIMP Palette
        Name: Xournal Default Palette
        #
        0 0 0 Black
        0 128 0 Green
        0 192 255 Light Blue
        0 255 0 Light Green
        51 51 204 Blue
        128 128 128 Gray
        255 0 0 Red
        255 0 255 Magenta
        255 128 0 Orange
        255 255 0 Yellow
        255 255 255 White
        245 247 73 Pastel Yellow
        255 164 0 Pastel Orange
        228 128 90 Pastel Terracotta
        245 115 106 Pastel Red
        229 152 155 Pastel Pink
        217 121 202 Pastel Purple
        196 241 190 Pastel Light Green
        129 164 134 Pastel Dark Green
        129 156 206 Pastel Light Blue
        69 165 205 Pastel Blue
        165 165 165 Pastel Gray
      '';
      force = true;
    };

    hm.xdg.configFile."xournalpp/toolbar.ini" = {
      text = ''
        [${toolbar.name}]
        toolbarTop1=${concatStringsSep "," toolbar.top}
        toolbarBottom1=${concatStringsSep "," toolbar.bottom}
        name=${toolbar.name}
      '';
      force = true;
    };
  };
}
