# Import packages from ../packages directory
let
  packagesDir = ../packages;
in
{ lib, ... }:
_final: prev:
let
  scope = lib.makeScope prev.newScope (_self: {
    inherit lib;
  });
in
{
  my = lib.packagesFromDirectoryRecursive {
    inherit (scope) newScope callPackage;
    directory = packagesDir;
  };
}
