{
  lib,
  pkgs,
  profiles,
  inputs,
  nixosConfigurations,
  ...
} @ args: let
  inherit (lib.dtc) rakeLeaves;

  /*
  Synopsis: mkPkgs overlays

  Generate an attribute set representing Nix packages with custom overlays.

  Inputs:
  - overlays: An attribute set of overlays to apply on top of the main Nixpkgs.

  Output Format:
  An attribute set representing Nix packages with custom overlays applied.
  The function imports the main Nixpkgs and applies additional overlays defined in the `overlays` argument.
  It then merges the overlays with the provided `argsPkgs` attribute set.

  */
  mkPkgs = overlays: let
    argsPkgs = {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in
    import inputs.nixpkgs ({
        overlays = lib.attrValues overlays;
      }
      // argsPkgs);

  /*
  Synopsis: mkOverlays overlaysDir

  Generate overlays for Nix expressions found in the specified directory.

  Inputs:
  - overlaysDir: The path to the directory containing Nix expressions.

  Output Format:
  An attribute set representing Nix overlays.
  The function recursively scans the `overlaysDir` directory for Nix expressions and imports each overlay.

  */
  mkOverlays = overlaysDir:
    lib.mapAttrsRecursive
    (_: module: import module {inherit rakeLeaves inputs;})
    (lib.dtc.rakeLeaves overlaysDir);

  /*
  Synopsis: mkProfiles profilesDir

  Generate profiles from the Nix expressions found in the specified directory.

  Inputs:
  - profilesDir: The path to the directory containing Nix expressions.

  Output Format:
  An attribute set representing profiles.
  The function uses the `rakeLeaves` function to recursively collect Nix files
  and directories within the `profilesDir` directory.
  The result is an attribute set mapping Nix files and directories
  to their corresponding keys.
  */
  mkProfiles = profilesDir: rakeLeaves profilesDir;

  /*
  Synopsis: mkHost hostname  { system, hostPath, extraModules ? [] }

  Generate a NixOS system configuration for the specified hostname.

  Inputs:
  - hostname: The hostname for the target NixOS system.
  - hostPath: The path to the directory containing host-specific Nix configurations.
  - system: The target system platform (e.g., "x86_64-linux").
  - extraArgs: Optional attributes to be passed down to all modules.
  - extraModules: An optional list of additional NixOS modules to include in the configuration.

  Output Format:
  A NixOS system configuration representing the specified hostname.
  The function generates a NixOS system configuration using the provided parameters and additional modules.
  It inherits attributes from `pkgs`, `lib`, `profiles`, `inputs`, `nixosConfigurations`, and other custom modules.
  */
  mkHost = hostname: {
    hostPath,
    system,
    extraArgs ? {},
    extraModules ? [],
    ...
  }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs =
        rec {
          inherit profiles inputs nixosConfigurations;
          secretsDir = ../secrets;
          hostSecretsDir = "${secretsDir}/${hostname}";
        }
        // extraArgs;
      modules =
        (lib.collect builtins.isPath (lib.dtc.rakeLeaves ../modules))
        ++ [
          {networking.hostName = hostname;}
          hostPath
        ]
        ++ extraModules;
    };

  /*
  Synopsis: mkHosts hostsDir

  Generate a set of NixOS system configurations for the hosts defined in the specified directory.

  Inputs:
  - hostsDir: The path to the directory containing host-specific configurations.
  - extraArgs: Optional attributes to be passed down to all modules.

  Output Format:
  An attribute set representing NixOS system configurations for the hosts
  found in the `hostsDir`. The function scans the `hostsDir` directory
  for host-specific Nix configurations and generates a set of NixOS
  system configurations for each host. The resulting attribute set maps
  hostnames to their corresponding NixOS system configurations.
  */
  mkHosts = hostsDir: {extraArgs ? {}, ...}:
    lib.listToAttrs (lib.lists.flatten (lib.mapAttrsToList (name: type: let
        # Get hostname from host path
        hostPath = hostsDir + "/${name}";
        configPath = hostPath + "/configuration.nix";
        hostname = lib.removeSuffix ".nix" (builtins.baseNameOf hostPath);

        # Merge default configuration with host configuration (if it exists)
        cfg =
          {
            inherit extraArgs hostPath inputs pkgs profiles;
            system = "x86_64-linux";
            aliases = null;
          }
          // hostCfg;

        hostCfg =
          lib.optionalAttrs
          (type == "directory" && builtins.pathExists configPath)
          (import configPath args);

        # Remove aliases from host configuration
        # and merge aliases with hosts
        aliases' =
          if (cfg.aliases != null)
          then cfg.aliases
          else {${hostname} = {extraModules = [];};};
        cfg' = lib.filterAttrs (name: _: name != "aliases") cfg;
        aliases = lib.mapAttrs (_: value: (value // cfg')) aliases';
      in (lib.mapAttrsToList (hostname: alias: {
          name = hostname;
          value = mkHost hostname alias;
        })
        aliases))
      # Ignore hosts starting with an underscore
      (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)) (builtins.readDir hostsDir))));
in {
  inherit mkPkgs mkOverlays mkProfiles mkHosts;
}
