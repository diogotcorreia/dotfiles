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
      # Nix Index (provides nix-locate to locate files in the Nix store)
      nix-index
      # timewarrior (time tracker)
      timewarrior
      # Rust
      rustup
    ];

    hm.programs.zsh.shellAliases."dig" = "${pkgs.dogdns}/bin/dog";

    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    hm.programs.git.ignores = [ ".envrc" ".direnv" ];

    # Android Debug Bridge
    usr.extraGroups = [ "adbusers" ];
    programs.adb.enable = true;
  };
}
