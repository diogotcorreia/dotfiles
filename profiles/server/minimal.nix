# Reduce closure size of system
{inputs, ...}: {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];
}
