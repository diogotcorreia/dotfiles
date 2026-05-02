# Configuration that should be applied to all systems
{
  lib,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    security.agenix
    services.ssh
    shell.fish
    shell.programs.essential
  ];

  # Modern defaults
  networking.nftables.enable = true;

  boot.kernelPackages = lib.mkIf (lib.versionOlder pkgs.linux.version "6.18.22") (
    lib.mkDefault pkgs.linuxPackages_6_18
  );
}
