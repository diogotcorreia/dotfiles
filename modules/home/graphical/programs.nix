# modules/home/graphical/programs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# misc GUI programs

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.programs;
in {
  options.modules.graphical.programs.enable = mkEnableOption "programs";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Discord
      discord-openasar
      # Insomnia REST Client
      insomnia
      # Telegram
      tdesktop
    ];

    # Video player
    programs.mpv.enable = true;

    # Configure MIME types for Telegram
    xdg.mimeApps.associations.added = {
      "x-scheme-handler/tg" = "userapp-Telegram Desktop-3BVMZ1.desktop";
    };
  };
}
