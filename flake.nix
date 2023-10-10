# flake.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# My config, based on RageKnify's

{
  description = "Nix configuration for PCs and servers.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence/master";
    home = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:the-argus/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-osc52 = {
      url = "github:ojroques/nvim-osc52/main";
      flake = false;
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ist-delegate-election = {
      url = "github:diogotcorreia/ist-delegate-election?ref=v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ ... }:
    let
      inherit (builtins) listToAttrs attrNames readDir filter;
      inherit (inputs.nixpkgs) lib;
      inherit (inputs.nixpkgs.lib.filesystem) listFilesRecursive;
      inherit (lib) mapAttrsToList hasSuffix;
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADPTInG2ZJ0LxO+IBJd1aORzmJlFPuJrcp4YRIJEE1s dtc@apollo"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlaWu32ANU+sWFcwKrPlqD/oW3lC3/hrA1Z3+ubuh5A dtc@bacchus"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYrpjewh+Z0IQkVLipcYJ0g0v1UJu49QmB9GTVUci11 dtc@ceres"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSySzB983nfhGMp++3FcpR0mwpYFiXu9XrGYwf/IH1w dtc@xiaomi11tpro"
      ];
      colors = {
        black = "#2E3440";
        white = "#D8DEE9";
        grey = "#373d49";
        lightblue = "#88C0D0";
        blue = "#81A1C1";
        darkblue = "#7292b2";
        red = "#BF616A";
        orange = "#D08770";
        yellow = "#EBCB8B";
        green = "#A3BE8C";
        pink = "#B48EAD";
      };

      systemFlakePath = "github:diogotcorreia/dotfiles/nixos";
      system = "x86_64-linux";
      user = "dtc";
      userFullName = "Diogo Correia";

      pkg-sets = final: prev:
        let
          args = {
            system = final.system;
            config.allowUnfree = true;
          };
        in { unstable = import inputs.nixpkgs-unstable args; };

      secretsDir = ./secrets;

      packagesDir = ./packages;

      overlaysDir = ./overlays;

      overlays = [ pkg-sets ] ++ mapAttrsToList (name: _:
        import "${overlaysDir}/${name}" { inherit inputs packagesDir; })
        (readDir overlaysDir);

      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      agenixPackage = inputs.agenix.packages.${system}.default;
      spicetifyPkgs = inputs.spicetify-nix.packages.${system}.default;

      allModules = mkModules ./modules;

      # Imports every nix module from a directory, recursively.
      mkModules = path: filter (hasSuffix ".nix") (listFilesRecursive path);

      # Imports every host defined in a directory.
      mkHosts = dir:
        listToAttrs (map (name: {
          inherit name;
          value = inputs.nixpkgs.lib.nixosSystem {
            inherit system pkgs;
            specialArgs = {
              inherit inputs user userFullName colors sshKeys agenixPackage
                secretsDir spicetifyPkgs systemFlakePath;
              configDir = ./config;
              hostSecretsDir = "${secretsDir}/${name}";
              hostName = name;
            };
            modules = [
              { networking.hostName = name; }
              inputs.home.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  sharedModules = [ inputs.spicetify-nix.homeManagerModule ];
                };
              }
              inputs.impermanence.nixosModules.impermanence
              inputs.agenix.nixosModules.default
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.disko.nixosModules.disko
              inputs.ist-delegate-election.nixosModules.default
            ] ++ allModules ++ (mkModules "${dir}/${name}");
          };
        }) (attrNames (readDir dir)));

    in { nixosConfigurations = mkHosts ./hosts; };
}
