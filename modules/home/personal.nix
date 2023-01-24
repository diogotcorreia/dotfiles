# modules/home/personal.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# configuration for personal computers.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;
in {
  options.modules.personal.enable = mkEnableOption "personal";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Discord
      discord-openasar
      # qalc (CLI calculator)
      libqalculate
      # Rust
      rustup
      pkgs.unstable.rust-analyzer
    ];
  };
}