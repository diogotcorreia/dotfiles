# modules/system.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/RageKnify/Config
#
# System config common across all hosts
{
  config,
  inputs,
  lib,
  secretsDir,
  ...
}: {
  # Contains:
  # machine nix-cache.diogotc.com
  # password <token>
  age.secrets.nixCacheDiogotcReadTokenNetrc.file = "${secretsDir}/nixCacheDiogotcReadTokenNetrc.age";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes" "repl-flake"];
      # Don't add @wheel here, since it allows for privilege escalation
      # https://github.com/NixOS/nix/issues/9649#issuecomment-1868001568
      trusted-users = ["root"];
      substituters = ["https://nix-cache.diogotc.com/dtc"];
      trusted-public-keys = ["dtc:HU5hQrzlNDSFAcA/kvzKx+IhyDYLvR+xUS/1drh3o2U="];
      netrc-file = config.age.secrets.nixCacheDiogotcReadTokenNetrc.path;
    };

    # Lock flake registry to keep it synced with the inputs
    # i.e. used by `nix run pkgs#<package>`
    registry = {
      pkgs.flake = inputs.nixpkgs; # alias to nixpkgs
      unstable.flake = inputs.nixpkgs-unstable;
      my.flake = inputs.self; # this flake itself
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

  # Avoid running out of space on the boot partition
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # dedup equal pages
  hardware.ksm = {
    enable = true;
    sleep = null;
  };
}
