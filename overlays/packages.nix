# Import packages from ../packages directory
# Adapted from https://github.com/luishfonseca/dotfiles/blob/6193dff46ad05eca77dedba9afbc50443a8b3dd1/overlays/packages.nix
let
  packagesDir = ../packages;
in
  {lib, ...}: final: prev: let
    callPackageFromAttrs = attrs:
      builtins.mapAttrs (
        name: value:
          if builtins.isAttrs value
          then (callPackageFromAttrs value)
          else (prev.callPackage value {inherit lib;})
      )
      attrs;
  in {
    my =
      callPackageFromAttrs
      (lib.my.rakeLeaves packagesDir);
  }
