# modules/home/graphical/spotify.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Spotify configuration and themeing with Spicetify

{ pkgs, config, lib, spicetifyPkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.spotify;
in {
  options.modules.graphical.spotify.enable = mkEnableOption "spotify";

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      theme = spicetifyPkgs.themes.Comfy;

      enabledExtensions = with spicetifyPkgs.extensions; [
        fullAppDisplay
        autoSkipVideo
        shuffle # shuffle+
        hidePodcasts
      ];

      enabledCustomApps = with spicetifyPkgs.apps; [ lyrics-plus ];
    };
  };
}
