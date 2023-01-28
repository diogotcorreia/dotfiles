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
        enable = true;
        desktop = "${config.home.homeDirectory}/.desktop";
        documents = "${config.home.homeDirectory}/documents";
        download = "${config.home.homeDirectory}/downloads";
        music = "${config.home.homeDirectory}/.music";
        pictures = "${config.home.homeDirectory}/pictures";
        publicShare = "${config.home.homeDirectory}/.public";
        templates = "${config.home.homeDirectory}/.templates";
        videos = "${config.home.homeDirectory}/videos";
      };
      configFile."mimeapps.list".force = true;
    };
  };
}
