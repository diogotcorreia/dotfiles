# modules/graphical/spotify.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Spotify configuration and themeing with Spicetify

{ config, lib, pkgs, spicetifyPkgs, ... }:
let
  inherit (lib) mkIf;
  cfg = config.modules.graphical.programs;
in {

  # Follow graphical.programs.enabled
  config = mkIf cfg.enable {
    # Allow mDNS discovery of Google Cast devices
    networking.firewall.allowedUDPPorts = [ 5353 ];

    hm.programs.spicetify = {
      enable = true;
      spotifyPackage = pkgs.unstable.spotify;
      spicetifyPackage = pkgs.unstable.spicetify-cli;

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
