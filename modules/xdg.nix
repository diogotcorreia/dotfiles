# modules/xdg.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# XDG home configuration
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.xdg;
in {
  options.modules.xdg.enable = mkEnableOption "xdg";

  # Home manager module
  config.hm = mkIf cfg.enable {
    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        desktop = "${config.my.homeDirectory}/.desktop";
        documents = "${config.my.homeDirectory}/documents";
        download = "${config.my.homeDirectory}/downloads";
        music = "${config.my.homeDirectory}/.music";
        pictures = "${config.my.homeDirectory}/pictures";
        publicShare = "${config.my.homeDirectory}/.public";
        templates = "${config.my.homeDirectory}/.templates";
        videos = "${config.my.homeDirectory}/videos";
      };
      configFile."mimeapps.list".force = true;
      configHome = "${config.my.homeDirectory}/.config";
    };
  };
}
