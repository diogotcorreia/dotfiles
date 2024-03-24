{lib, ...} @ args: let
  listModulesRecursive = dir:
    lib.filter
    (p: lib.hasSuffix ".nix" p && !(lib.hasPrefix "_" (builtins.baseNameOf p)))
    (lib.filesystem.listFilesRecursive dir);
in {
  dtc = {inherit listModulesRecursive;} // lib.foldr (path: acc: acc // (import path args)) {} (listModulesRecursive ./.);
}
