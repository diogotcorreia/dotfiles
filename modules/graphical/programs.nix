# modules/graphical/programs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# misc GUI programs

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.programs;
in {
  options.modules.graphical.programs.enable = mkEnableOption "programs";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # Discord
      discord-openasar
      # Telegram
      tdesktop
      # Signal
      signal-desktop
    ];

    # Video player
    hm.programs.mpv.enable = true;

    # Bluetooth device manager
    services.blueman.enable = config.hardware.bluetooth.enable;
  };
}
