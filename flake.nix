{
  description = "Diogo Correia's Nix(OS) configuration for PCs and servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence/master";
    home = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      # we don't use darwin, so we can get rid of it
      inputs.darwin.follows = "";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
      # only used for development, so we can get rid of it
      inputs.pre-commit-hooks-nix.follows = "";
      # only used for non-flake setups, so we can get rid of it
      inputs.flake-compat.follows = "";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lidl-to-grocy = {
      url = "github:diogotcorreia/lidl-to-grocy?ref=v1.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    infra-keyval = {
      url = "github:diogotcorreia/infra-keyval";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {...}: let
    inherit (lib.my) mkHosts mkOverlays mkPkgs mkProfiles mkSecrets;

    user = "dtc";
    userFullName = "Diogo Correia";

    extraArgs = {
      inherit
        user
        userFullName
        ;
      configDir = ./config;
    };

    lib = inputs.nixpkgs.lib.extend (self: super:
      import ./lib ({
          inherit inputs nixosConfigurations profiles pkgs secrets;
          lib = self;
        }
        // extraArgs));

    extraPackages = {system, ...}: {
      agenix = inputs.agenix.packages.${system}.default;
      lidl-to-grocy = inputs.lidl-to-grocy.packages.${system}.default;
      spicetify = inputs.spicetify-nix.legacyPackages.${system};
    };

    overlays =
      (mkOverlays ./overlays)
      // {
        extraPkgs = self: super: (extraPackages {system = "x86_64-linux";});
      };
    pkgs = mkPkgs overlays;
    nixosConfigurations = mkHosts ./hosts {
      inherit extraArgs;
      # TODO move to profiles
      extraModules = [
        {
          hardware.enableRedistributableFirmware = true;
        }
        inputs.home.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
        inputs.impermanence.nixosModules.impermanence
        inputs.lanzaboote.nixosModules.lanzaboote
      ];
    };
    profiles = mkProfiles ./profiles;
    secrets = mkSecrets ./secrets;
  in {
    inherit nixosConfigurations lib overlays;

    # Packages are here so they are built by CI and cached
    packages = {
      x86_64-linux =
        pkgs.my
        // {
          attic = pkgs.attic-client;
          infra-keyval = inputs.infra-keyval.packages.x86_64-linux.infra-keyval;
          ironbar = pkgs.my.ironbar-unstable;
          lzbt = inputs.lanzaboote.packages.x86_64-linux.lzbt;
        };
    };

    formatter = {
      # https://github.com/NixOS/nix/pull/11438#issuecomment-2343378813
      x86_64-linux = pkgs.writeShellScriptBin "formatter" ''
        # If no arguments are passed, default to formatting the whole project
        if [[ $# = 0 ]]; then
          prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
          set -- "$prj_root"
        fi

        "${lib.getExe pkgs.deadnix}" --hidden --edit "$@"
        "${lib.getExe pkgs.alejandra}" "$@"
      '';
    };
  };
}
