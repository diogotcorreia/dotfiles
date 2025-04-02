# Configuration for development (IDEs and other tools).
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.development;
in {
  options.modules.graphical.development.enable =
    mkEnableOption "development tools and IDEs";

  # Home manager module
  config.hm = mkIf cfg.enable {
    home.packages = with pkgs; [
      # IntelliJ IDEA (Ultimate)
      unstable.jetbrains.idea-ultimate
      # TODO: use stable on nixos-25.05
      # REST Client
      unstable.yaak
    ];

    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
  };
}
