# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  discordThemeFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.11.1/nordic.theme.css";
    hash = "sha256-2g3iPow3Pkqcvt56CGocWD5jZsNWdCthkmFXsy09UCM=";
  };
  extraCss = ''
    .visual-refresh.theme-dark {
      /* change background color of chat pane */
      --neutral-69: var(--nord-dark1) !important;
      /* change background color of left pane */
      --neutral-83: var(--nord-dark1) !important;
      /* change background of action buttons */
      --background-secondary: var(--nord-dark2) !important;
      /* change background of "active now" pane */
      --bg-overlay-2: var(--nord-dark1) !important;
    }
    .visual-refresh .sidebarList_c48ade {
      /* add missing border since background is the same now */
      border-right: 1px solid var(--app-border-frame);
    }
    .bar_c38106 {
      /* hide top bar */
      /* hide overflow instead of display: none; so that CTRL + I still works for inbox */
      overflow: hidden;
    }
    .visual-refresh {
      /* hide top bar */
      --custom-app-top-bar-height: 0;
    }
  '';

  settings = {
    openasar = {
      setup = true;
      cmdPreset =
        if config.my.hardware.laptop
        then "battery"
        else "perf";
      quickstart = true;
    };
    DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    SKIP_HOST_UPDATE = true;
    MINIMIZE_TO_TRAY = false;
    OPEN_ON_STARTUP = false;
  };

  settingsFile =
    pkgs.runCommand "settings-override.json" {
      nativeBuildInputs = with pkgs; [jq];
    } ''
      jq --argjson cfg ${lib.escapeShellArg (builtins.toJSON settings)} \
        --arg css "$(<${discordThemeFile})" \
        --arg extraCss ${lib.escapeShellArg extraCss} \
        '$cfg * (.openasar.css = $css + "\n" + $extraCss)' -n > $out
    '';
in {
  hm.home.packages = with pkgs; [
    # Discord
    discord-openasar
  ];

  # Discord configuration
  hm.xdg.configFile."discord/settings-override.json".source = settingsFile;
}
