# modules/kth.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for services and programs needed while studying
# at Royal Institute of Technology (KTH).

{ pkgs, config, lib, secretsDir, ... }:
let
  inherit (lib) mkEnableOption mkIf escapeShellArg getAttr attrNames;
  cfg = config.modules.kth;
in {
  options.modules.kth.enable = mkEnableOption "kth";

  config = mkIf cfg.enable { };
}
