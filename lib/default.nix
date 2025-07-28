{ lib, ... }@args:
let
  listFilesWithSuffixRecursive =
    suffix: dir:
    lib.filter (p: lib.hasSuffix suffix p && !(lib.hasPrefix "_" (builtins.baseNameOf p))) (
      lib.filesystem.listFilesRecursive dir
    );

  listModulesRecursive = listFilesWithSuffixRecursive ".nix";

  listModulesRecursive' = dir: lib.filter (p: p != dir + "/default.nix") (listModulesRecursive dir);
in
{
  my = {
    inherit listFilesWithSuffixRecursive listModulesRecursive listModulesRecursive';
  }
  // lib.foldr (path: acc: acc // (import path args)) { } (listModulesRecursive' ./.);
}
