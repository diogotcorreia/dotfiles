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

  config = mkIf cfg.enable {
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark; # use Qt version instead of CLI version
    };
    usr.extraGroups = [
      "wireshark"
      "dialout" # access USB TTY devices without sudo
    ];

    hm.home.packages = with pkgs; [
      # Enhanced GDB
      gef
      # hx (hexdump replacement)
      hex
      # Java Decompiler
      jadx
      # Binary Decompiler
      ghidra-bin
    ];
  };
}
