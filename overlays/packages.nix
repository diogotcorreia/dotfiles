# Import packages from ../packages directory
# Adapted from https://github.com/luishfonseca/dotfiles/blob/6193dff46ad05eca77dedba9afbc50443a8b3dd1/overlays/packages.nix
let
  packagesDir = ../packages;
in
  {...}: final: prev: {
    my = prev.lib.mapAttrs' (name: value:
      prev.lib.nameValuePair (prev.lib.removeSuffix ".nix" name)
      (prev.callPackage "${packagesDir}/${name}" {}))
    (builtins.readDir packagesDir);
  }
