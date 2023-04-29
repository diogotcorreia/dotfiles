# modules/home/graphical/development.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for development (IDEs and other tools).

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.development;
in {
  options.modules.graphical.development.enable =
    mkEnableOption "development tools and IDEs";

  # Home manager module
  config.hm = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Jetbrains Gateway (remote development)
      unstable.jetbrains.gateway
      # IntelliJ IDEA (Ultimate)
      unstable.jetbrains.idea-ultimate
      # Visual Studio Code
      unstable.vscode
      # Insomnia REST Client
      unstable.insomnia
    ];

    # Firefox browser
    programs.firefox.enable = true;
  };
}
