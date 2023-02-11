# modules/personal.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# non-graphical configuration for personal computers.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;
in {
  options.modules.personal.enable = mkEnableOption "personal";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # dog DNS CLI client (dig alternative)
      dogdns
      # qalc (CLI calculator)
      libqalculate
      # LaTeX
      texlive.combined.scheme-small
      texlab
      # timewarrior (time tracker)
      timewarrior
      # Rust
      rustup
      pkgs.unstable.rust-analyzer
    ];

    hm.programs.zsh.shellAliases."dig" = "${pkgs.dogdns}/bin/dog";

    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Android Debug Bridge
    usr.extraGroups = [ "adbusers" ];
    programs.adb.enable = true;
  };
}
