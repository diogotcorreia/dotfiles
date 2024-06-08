# misc GUI programs
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.graphical.programs;

  discordThemeFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.10.9/uniform/nordic.theme.css";
    hash = "sha256-SDLprtPs4F3NirCHn/SL7WAWl8iK0+4JglVr6oP0ejs=";
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

          /* fix for broken background on server icon list */
          .wrapper__216eb {
            background-color: var(--background-primary);
            border-right: 1px solid var(--background-secondary-alt);
          }

          /* fix for other's reactions being too light */
          .reaction__4a43f {
            background: var(--background-secondary) !important;
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
