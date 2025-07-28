# Reduce closure size of system
{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];

  hm.programs.man.enable = false;

  hm.manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
