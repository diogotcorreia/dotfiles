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
      # Bruno REST Client
      unstable.bruno
      # IntelliJ IDEA (Ultimate)
      unstable.jetbrains.idea-ultimate
    ];

    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
  };
}
