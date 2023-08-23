# modules/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/RageKnify/Config
#
# System config common across all hosts

{ inputs, pkgs, lib, ... }: {
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
    };

    # Lock flake registry to keep it synced with the inputs
    # i.e. used by `nix run pkgs#<package>`
    registry = {
      pkgs.flake = inputs.nixpkgs; # alias to nixpkgs
      unstable.flake = inputs.nixpkgs-unstable;
    };

    nixPath = [
      "nixpkgs=/etc/channels/nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

  security.sudo.extraConfig = ''
    Defaults lecture=never
  '';

  # Every host shares the same time zone.
  # TODO perhaps set this per host
  time.timeZone = lib.mkDefault "Europe/Lisbon";

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  # dedup equal pages
  hardware.ksm = {
    enable = true;
    sleep = null;
  };
}
