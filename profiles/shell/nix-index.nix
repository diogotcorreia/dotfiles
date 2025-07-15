# Setup nix-index with pre-built database
{inputs, ...}: {
  home-manager.sharedModules = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  hm.programs.nix-index.enable = true;
}
