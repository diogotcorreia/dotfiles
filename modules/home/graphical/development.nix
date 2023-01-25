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
  options.modules.graphical.development.enable = mkEnableOption "development";

  config = mkIf cfg.enable {
    home.packages = [
      # Jetbrains Gateway (remote development)
      pkgs.unstable.jetbrains.gateway
      # IntelliJ IDEA (Ultimate)
      pkgs.unstable.jetbrains.idea-ultimate
      # Visual Studio Code
      pkgs.unstable.vscode
    ];
  };
}
