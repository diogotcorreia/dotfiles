# This is here to allow custom packages to be imported
# from non-flakes (e.g., shell.nix).
{nixpkgs ? <nixpkgs>}: let
  pkgs = import nixpkgs {
    overlays = [(import ./overlays/packages.nix {inherit lib;})];
    config = {
      allowUnfree = true;
    };
  };

  lib = pkgs.lib.extend (self: super: {
    my = import ./lib/importers.nix {
      lib = self;
    };
  });
in
  pkgs.my
