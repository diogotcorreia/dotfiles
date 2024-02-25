# modules/graphical/programs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# misc GUI programs
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.graphical.programs;

  discordThemeFile = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.10.8/uniform/nordic.theme.css";
    sha256 = "sha256-nsz20H5Vc79DVkL4dE+0y3FRJiN88Z7aJPRchIImTYY=";
  };
in {
  options.modules.graphical.programs.enable = mkEnableOption "programs";
  options.modules.graphical.programs.laptop = mkOption {
    type = types.bool;
    default = false;
    example = true;
    description = "Whether the device is a laptop or not.";
  };

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # Anki Flashcards
      unstable.anki-bin
      # Discord
      discord-openasar
      # Telegram
      tdesktop
      # Thunderbird
      thunderbird
      # Android screen mirroring (scrcpy)
      scrcpy
      # Signal
      signal-desktop
    ];

    # Video player
    hm.programs.mpv.enable = true;

    # Bluetooth device manager
    services.blueman.enable = config.hardware.bluetooth.enable;

    # Discord configuration
    hm.xdg.configFile."discord/settings-override.json".text = builtins.toJSON {
      openasar = {
        setup = true;
        cmdPreset =
          if cfg.laptop
          then "battery"
          else "perf";
        quickstart = true;
        css = ''
          ${builtins.readFile discordThemeFile}

          .theme-dark {
            --background-primary: var(--primary-630);
            --background-secondary: var(--primary-600);
            --background-tertiary: var(--primary-700);
          }

          /* fix for broken background when hovering mentions */
          .mouse-mode.full-motion .mentioned__58017:hover {
            background-color: var(--background-mentioned-hover) !important;
          }
        '';
      };
      DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
      SKIP_HOST_UPDATE = true;
      MINIMIZE_TO_TRAY = false;
      OPEN_ON_STARTUP = false;
    };
  };
}
