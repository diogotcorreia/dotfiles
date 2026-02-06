# System config common across all hosts
{
  config,
  inputs,
  lib,
  secrets,
  ...
}:
{
  # Contains:
  # machine nix-cache.diogotc.com
  # password <token>
  age.secrets.nixCacheDiogotcReadTokenNetrc.file = secrets.nixCacheDiogotcReadTokenNetrc;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Don't add @wheel here, since it allows for privilege escalation
      # https://github.com/NixOS/nix/issues/9649#issuecomment-1868001568
      trusted-users = [ "root" ];
      substituters = [ "https://nix-cache.diogotc.com/dtc" ];
      trusted-public-keys = [ "dtc:HU5hQrzlNDSFAcA/kvzKx+IhyDYLvR+xUS/1drh3o2U=" ];
      # File contents:
      # machine nix-cache.diogotc.com
      # password <attic token>
      netrc-file = config.age.secrets.nixCacheDiogotcReadTokenNetrc.path;

      # https://jackson.dev/post/nix-reasonable-defaults/
      fallback = true; # skip offline binary-caches (can end up building from source)

      # Use substituters even for trivial derivations
      always-allow-substitutes = true;
    };

    # Lock flake registry to keep it synced with the inputs
    # i.e. used by `nix run pkgs#<package>`
    registry = rec {
      # not using `input.<name>` here in order to not bloat the closure size
      nixpkgs.to = pkgs.to;
      # alias to nixpkgs
      pkgs.to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (inputs.nixpkgs.sourceInfo) lastModified narHash rev;
      };
      unstable.to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (inputs.nixpkgs-unstable.sourceInfo) lastModified narHash rev;
      };
      # not using `input.self` here in order to avoid rebuilding every system on every update
      my.to = {
        type = "github";
        owner = "diogotcorreia";
        repo = "dotfiles";
        ref = "refs/heads/nixos";
      };
    };

    nixPath = [
      "nixpkgs=flake:pkgs"
      "unstable=flake:unstable"
      "my=flake:my"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture=never
  '';

  # Every host shares the same time zone.
  # TODO perhaps set this per host
  time.timeZone = lib.mkDefault "Europe/Lisbon";

  networking.domain = lib.mkDefault "diogotc.com";

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  # Avoid running out of space on the boot partition
  boot.loader.grub.configurationLimit = lib.mkDefault 10;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # dedup equal pages
  hardware.ksm = {
    enable = true;
    sleep = null;
  };
}
