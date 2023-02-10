# modules/cybersec.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Cybersecurity and CTF related tools.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.cybersec;
in {
  options.modules.cybersec.enable = mkEnableOption "cybersec";

  # Home manager module
  config.hm = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Enhanced GDB
      gef
      # hx (hexdump replacement)
      hex
      # Java Decompiler
      jadx
    ];
  };
}
