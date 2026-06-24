{
  description = "Diogo Correia's Nix(OS) configuration for PCs and servers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home";
    };
    home = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      # we don't use darwin, so we can get rid of it
      inputs.darwin.follows = "";
      # used for tests only
      inputs.home-manager.follows = "";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote?ref=v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
      # only used for development, so we can get rid of it
      inputs.pre-commit.follows = "";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # pwndbg has been removed from nixpkgs, so we use it here to
    # allow it to be cached and re-exported for my ctf flake
    # https://github.com/NixOS/nixpkgs/pull/380600
    pwndbg = {
      url = "github:pwndbg/pwndbg?ref=2026.02.18";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lidl-to-grocy = {
      url = "github:diogotcorreia/lidl-to-grocy?ref=v1.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    infra-keyval = {
      url = "github:diogotcorreia/infra-keyval?ref=v0.1.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ist-discord-bot = {
      url = "github:ist-bot-team/ist-discord-bot?ref=v3.0.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-build-failure-notifier = {
      url = "github:diogotcorreia/nixpkgs-build-failure-notifier?ref=v0.3.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    inputs@{ ... }:
    let
      inherit (lib.my)
        mkHosts
        mkOverlays
        mkPkgs
        mkProfiles
        mkSecrets
        ;

      user = "dtc";
      userFullName = "Diogo Correia";

      extraArgs = {
        inherit
          user
          userFullName
          ;
        configDir = ./config;
      };

      lib = inputs.nixpkgs.lib.extend (
        self: _super:
        import ./lib (
          {
            inherit
              inputs
              nixosConfigurations
              profiles
              pkgs
              secrets
              ;
            lib = self;
          }
          // extraArgs
        )
      );

      extraPackages =
        { system, ... }:
        {
          agenix = inputs.agenix.packages.${system}.default;
          ist-discord-bot = inputs.ist-discord-bot.packages.${system}.default;
          lidl-to-grocy = inputs.lidl-to-grocy.packages.${system}.default;
          spicetify = inputs.spicetify-nix.legacyPackages.${system};
        };

      overlays = (mkOverlays ./overlays) // {
        extraPkgs = _self: _super: (extraPackages { system = "x86_64-linux"; });
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
    in
    {
      inherit nixosConfigurations lib overlays;

      # Packages are here so they are built by CI and cached
      packages = {
        x86_64-linux = pkgs.my // {
          inherit (pkgs) restic-without-rclone;
          attic = pkgs.attic-client;
          inherit (inputs.infra-keyval.packages.x86_64-linux) infra-keyval;
          inherit (inputs.ist-discord-bot.packages.x86_64-linux) ist-discord-bot;
          inherit (inputs.lanzaboote.packages.x86_64-linux) lzbt;
          inherit (inputs.nixpkgs-build-failure-notifier.packages.x86_64-linux)
            nixpkgs-build-failure-notifier
            ;
          inherit (inputs.pwndbg.packages.x86_64-linux) pwndbg;
        };
      };

      formatter = {
        x86_64-linux = pkgs.my.formatter;
      };
    };
}
