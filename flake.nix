{
  description = "Diogo Correia's Nix(OS) configuration for PCs and servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence/master";
    home = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:MichaelPachec0/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    lidl-to-grocy = {
      url = "github:diogotcorreia/lidl-to-grocy?ref=v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {...}: let
    inherit (lib.my) mkHosts mkOverlays mkPkgs mkProfiles mkSecrets;

    systemFlakePath = "github:diogotcorreia/dotfiles/nixos";
    user = "dtc";
    userFullName = "Diogo Correia";

    extraArgs = {
      inherit
        systemFlakePath # TODO move to profile
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
      spicetify = inputs.spicetify-nix.packages.${system}.default;
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
            sharedModules = [inputs.spicetify-nix.homeManagerModule];
          };
        }
        inputs.impermanence.nixosModules.impermanence
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.attic.nixosModules.atticd
      ];
    };
    profiles = mkProfiles ./profiles;
    secrets = mkSecrets ./secrets;
  in {
    inherit nixosConfigurations lib overlays;

    # Packages are here so they are built by CI and cached
    packages = {
      x86_64-linux = {
        attic = inputs.attic.packages.x86_64-linux.attic-nixpkgs.override {clientOnly = true;};

        # TODO this should be auto generated
        inherit (pkgs.my) alt-urls-discord-bot flask-unsign githacker jwt-tool pycdc pyinstxtractor;
      };
    };

    formatter = {
      x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
    };
  };
}
