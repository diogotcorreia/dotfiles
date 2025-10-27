# misc GUI programs
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.programs;
in
{
  options.modules.graphical.programs.enable = mkEnableOption "programs";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # Anki Flashcards
      unstable.anki # TODO 25.11: use stable
      # Telegram
      tdesktop
      # Android screen mirroring (scrcpy)
      scrcpy
      # Signal
      signal-desktop
    ];

    # Video player
    hm.programs.mpv.enable = true;
  };
}
