# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  discordThemeFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.12.3/nordic.theme.css";
    hash = "sha256-ETN/eShl6uX0TK6OUjLeNP8RdymVK2BuO7XFUwrQQYI=";
  };
  extraCss = ''
    .theme-dark, .theme-darker {
      /* change background color of chat pane */
      --background-base-lower: var(--nord-dark1) !important;
      /* change background color of text input */
      --chat-background-default: var(--nord-dark2) !important;
      /* change background color of "active now" cards */
      --background-surface-high: var(--nord-dark1) !important;
      /* change background of action buttons */
      --background-secondary: var(--nord-dark2) !important;
      /* change background of "active now" pane */
      --background-base-low: var(--nord-dark1) !important;
    }
    ._5e434347c823b592-sidebarList {
      /* add missing border since background is the same now */
      border-right: 1px solid var(--app-frame-border);
    }
    .c38106a3f0c3ca76-bar {
      /* hide top bar */
      /* hide overflow instead of display: none; so that CTRL + I still works for inbox */
      overflow: hidden;
    }
    :root {
      /* hide top bar */
      --custom-app-top-bar-height: 0px !important;
    }
  '';

  settings = {
    openasar = {
      setup = true;
      cmdPreset = if config.my.hardware.laptop then "battery" else "perf";
      quickstart = true;
    };
    DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    SKIP_HOST_UPDATE = true;
    MINIMIZE_TO_TRAY = false;
    OPEN_ON_STARTUP = false;
  };

  settingsFile =
    pkgs.runCommand "settings-override.json"
      {
        nativeBuildInputs = with pkgs; [ jq ];
      }
      ''
        jq --argjson cfg ${lib.escapeShellArg (builtins.toJSON settings)} \
          --arg css "$(<${discordThemeFile})" \
          --arg extraCss ${lib.escapeShellArg extraCss} \
          '$cfg * (.openasar.css = $css + "\n" + $extraCss)' -n > $out
      '';
in
{
  hm.home.packages = with pkgs; [
    # Discord
    discord-openasar
  ];

  # Discord configuration
  hm.xdg.configFile."discord/settings-override.json".source = settingsFile;
}
