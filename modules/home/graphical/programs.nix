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
    ];

    # Video player
    programs.mpv.enable = true;
  };
}