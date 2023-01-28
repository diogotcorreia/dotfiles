# modules/home/xdg.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# XDG home configuration

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.xdg;
in {
  options.modules.xdg.enable = mkEnableOption "xdg";

  config = mkIf cfg.enable {
    xdg = {
      enable = true;
      userDirs = {
        desktop = "$HOME/.desktop";
        documents = "$HOME/documents";
        download = "$HOME/downloads";
        music = "$HOME/.music";
        pictures = "$HOME/pictures";
        publicShare = "$HOME/.public";
        templates = "$HOME/.templates";
        videos = "$HOME/videos";
      };
      configFile."mimeapps.list".force = true;
    };
  };
}
