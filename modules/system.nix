# System config common across all hosts
{
  config,
  inputs,
  lib,
  secrets,
  ...
}: {
  # Contains:
  # machine nix-cache.diogotc.com
  # password <token>
  age.secrets.nixCacheDiogotcReadTokenNetrc.file = secrets.nixCacheDiogotcReadTokenNetrc;

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

      # https://jackson.dev/post/nix-reasonable-defaults/
      fallback = true; # skip offline binary-caches (can end up building from source)
    };

    # Lock flake registry to keep it synced with the inputs
    # i.e. used by `nix run pkgs#<package>`
    registry = {
      pkgs.flake = inputs.nixpkgs; # alias to nixpkgs
      unstable.flake = inputs.nixpkgs-unstable;
      my.flake = inputs.self; # this flake itself
    };

    nixPath = [
      "nixpkgs=flake:pkgs"
      "my=flake:my"
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
