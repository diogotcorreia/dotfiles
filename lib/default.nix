{lib, ...} @ args: let
  listModulesRecursive = dir:
    lib.filter
    (p: lib.hasSuffix ".nix" p && !(lib.hasPrefix "_" (builtins.baseNameOf p)))
    (lib.filesystem.listFilesRecursive dir);

  listModulesRecursive' = dir:
    lib.filter
    (p: p != dir + "/default.nix")
    (listModulesRecursive dir);
in {
  my =
    {
      inherit listModulesRecursive listModulesRecursive';
    }
    // lib.foldr (path: acc: acc // (import path args)) {} (listModulesRecursive' ./.);
}
