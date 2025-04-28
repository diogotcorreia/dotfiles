# Spotify configuration and themeing with Spicetify
{
  inputs,
  lib,
  pkgs,
  ...
}: {
  home-manager.sharedModules = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  # Allow mDNS discovery of Google Cast devices
  networking.firewall.allowedUDPPorts = [lib.my.ports.mdnsGoogleCast];

  hm.programs.spicetify = {
    enable = true;
    spotifyPackage = pkgs.spotify;

    theme = pkgs.spicetify.themes.comfy;
    colorScheme = "Comfy";

    enabledExtensions = with pkgs.spicetify.extensions; [
      fullAppDisplay
      autoSkipVideo
      shuffle # shuffle+
      hidePodcasts
    ];

    enabledCustomApps = with pkgs.spicetify.apps; [lyricsPlus];
  };
}
