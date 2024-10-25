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
      url = "github:Gerg-L/spicetify-nix";
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
      url = "github:diogotcorreia/lidl-to-grocy?ref=v1.3.0";
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
            sharedModules = [inputs.spicetify-nix.homeManagerModules.default];
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
      x86_64-linux =
        pkgs.my
        // {
          attic = inputs.attic.packages.x86_64-linux.attic-nixpkgs.override {clientOnly = true;};
          # TODO: remove when fixed upstream
          # Apparently hydra failed to build this, and because it's cached it's not trying again
          # https://hydra.nixos.org/build/276260138
          stalwart-mail = pkgs.unstable.stalwart-mail;
        };
    };

    formatter = {
      x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
    };
  };
}
