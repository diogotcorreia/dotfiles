{
  inputs,
  lib,
  nixosConfigurations,
  pkgs,
  profiles,
  secrets,
  ...
}@args:
let
  inherit (lib.my) listModulesRecursive' rakeLeaves rakeLeavesWithSuffix;

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
  mkPkgs =
    overlays:
    let
      argsPkgs = {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    import inputs.nixpkgs (
      {
        overlays = [
          (_self: _super: {
            unstable = import inputs.nixpkgs-unstable argsPkgs;
          })
        ]
        ++ lib.attrValues overlays;
      }
      // argsPkgs
    );

  /*
    Synopsis: mkOverlays overlaysDir

    Generate overlays for Nix expressions found in the specified directory.

    Inputs:
    - overlaysDir: The path to the directory containing Nix expressions.

    Output Format:
    An attribute set representing Nix overlays.
    The function recursively scans the `overlaysDir` directory for Nix expressions and imports each overlay.
  */
  mkOverlays =
    overlaysDir:
    lib.mapAttrsRecursive (_: module: import module { inherit lib rakeLeaves inputs; }) (
      rakeLeaves overlaysDir
    );

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
    Synopsis: mkSecrets secretsDir

    Generate a secrets attributes from the age files found in the specified directory.

    Inputs:
    - secretsDir: The path to the directory containing encrypted age files.

    Output Format:
    An attribute set representing profiles.
    The function uses the `rakeLeavesWithSuffix` function to recursively collect age files
    and directories within the `secretsDir` directory.
    The result is an attribute set mapping age files and directories
    to their corresponding keys.
  */
  mkSecrets = secretsDir: rakeLeavesWithSuffix ".age" { } secretsDir;

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
  mkHost =
    hostname:
    {
      hostPath,
      system,
      extraArgs ? { },
      extraModules ? [ ],
      ...
    }:
    lib.nixosSystem {
      inherit system pkgs lib;
      specialArgs = {
        inherit profiles inputs nixosConfigurations;
        secrets = secrets // {
          host = secrets.${hostname};
        };
      }
      // extraArgs;
      modules =
        (lib.collect builtins.isPath (rakeLeaves ../modules))
        ++ [
          { networking.hostName = hostname; }
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
    - extraModules: An optional list of additional NixOS modules to include in all configurations.

    Output Format:
    An attribute set representing NixOS system configurations for the hosts
    found in the `hostsDir`. The function scans the `hostsDir` directory
    for host-specific Nix configurations and generates a set of NixOS
    system configurations for each host. The resulting attribute set maps
    hostnames to their corresponding NixOS system configurations.
  */
  mkHosts =
    hostsDir:
    {
      extraArgs ? { },
      extraModules ? [ ],
      ...
    }:
    lib.pipe (builtins.readDir hostsDir) [
      # Ignore hosts starting with an underscore
      (lib.filterAttrs (path: _: !(lib.hasPrefix "_" path)))
      # Generate host
      (lib.mapAttrs' (
        name: type:
        let
          # Get hostname from host path
          hostPath = hostsDir + "/${name}";
          configPath = hostPath + "/configuration.nix";
          hostname = lib.removeSuffix ".nix" (builtins.baseNameOf hostPath);

          extraHostModules =
            if type == "directory" then
              (lib.filter (p: p != hostPath + "/configuration.nix") (listModulesRecursive' hostPath))
            else
              [ ];

          # Merge default configuration with host configuration (if it exists)
          cfg = {
            inherit
              extraArgs
              hostPath
              inputs
              pkgs
              profiles
              ;
            system = "x86_64-linux";

            extraModules = extraHostModules ++ extraModules;
          }
          // hostCfg;

          hostCfg = lib.optionalAttrs (type == "directory" && builtins.pathExists configPath) (
            import configPath args
          );
        in
        lib.nameValuePair hostname (mkHost hostname cfg)
      ))
    ];
in
{
  inherit
    mkPkgs
    mkOverlays
    mkProfiles
    mkSecrets
    mkHosts
    ;
}
