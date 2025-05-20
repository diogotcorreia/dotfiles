{lib, ...}: let
  rakeLeaves = rakeLeavesWithSuffix ".nix" {defaultName = "default";};

  rakeLeavesWithSuffix =
    /*
    Synopsis: rakeLeavesWithSuffix _suffix_ _args_ _path_

    Recursively collect the files with _suffix_ of _path_ into attrs.

    Output Format:
    An attribute set where all files ending in _suffix_ and directories with _defaultName_+_suffix_ in them
    are mapped to keys that are either the file with _suffix_ stripped or the folder name.
    All other directories are recursed further into nested attribute sets with the same format.

    Example file structure (with _suffix_ ".nix", _defaultName_ "default"):
    ```
    ./core/default.nix
    ./base.nix
    ./main/dev.nix
    ./main/os/default.nix
    ```

    Example output:
    ```
    {
      core = ./core;
      base = base.nix;
      main = {
        dev = ./main/dev.nix;
        os = ./main/os;
      };
    }
    ```
    */
    suffix: args @ {defaultName ? null}: dirPath: let
      seive = file: type:
      # Only rake files ending in suffix or directories
        (type == "regular" && lib.hasSuffix suffix file) || (type == "directory");

      collect = file: type: {
        name = lib.removeSuffix suffix file;
        value = let
          path = dirPath + "/${file}";
        in
          if
            (type == "regular")
            || (defaultName != null && type == "directory" && builtins.pathExists (path + "/${defaultName}${suffix}"))
          then path
          # recurse on directories that don't contain a default file
          else rakeLeavesWithSuffix suffix args path;
      };

      files = lib.filterAttrs seive (builtins.readDir dirPath);
    in
      lib.filterAttrs (_n: v: v != {}) (lib.mapAttrs' collect files);
in {
  inherit rakeLeaves rakeLeavesWithSuffix;
}
