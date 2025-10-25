# Reduce closure size of system
{ inputs, lib, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];

  programs.nano.enable = false;

  # this is only useful for GUI
  fonts.fontconfig.enable = false;
  xdg.menus.enable = false;
  appstream.enable = false;

  # these hosts are not using bcache
  boot.bcache.enable = false;

  # no need to manage sleep and powersaving
  powerManagement.enable = false;

  # disable all these tools I don't need on servers
  # nixos-rebuild is not needed as I have my own deploy script
  system.tools = {
    nixos-rebuild.enable = false;
    nixos-generate-config.enable = false;
    nixos-build-vms.enable = false;
    nixos-install.enable = false;
    nixos-version.enable = false;
    nixos-enter.enable = false;
    nixos-option.enable = false;
  };

  hm.programs.man.enable = false;

  hm.manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
