# Spotify configuration and themeing with Spicetify
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.modules.graphical.programs;
in {
  # Follow graphical.programs.enabled
  config = mkIf cfg.enable {
    # Allow mDNS discovery of Google Cast devices
    networking.firewall.allowedUDPPorts = [5353];

    hm.programs.spicetify = {
      enable = true;
      spotifyPackage = pkgs.unstable.spotify;
      spicetifyPackage = pkgs.unstable.spicetify-cli;

      theme = pkgs.spicetify.themes.Comfy;

      enabledExtensions = with pkgs.spicetify.extensions; [
        fullAppDisplay
        autoSkipVideo
        shuffle # shuffle+
        hidePodcasts
      ];

      enabledCustomApps = with pkgs.spicetify.apps; [lyrics-plus];
    };
  };
}
