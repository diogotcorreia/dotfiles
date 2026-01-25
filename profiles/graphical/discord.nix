# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  discordThemeFile = "${pkgs.my.discord-nordic}/nordic.theme.css";
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
    .sidebarList__5e434 {
      /* add missing border since background is the same now */
      border-right: 1px solid var(--app-frame-border);
    }
    .bar_c38006 {
      /* hide top bar */
      /* hide overflow instead of display: none; so that CTRL + I still works for inbox */
      overflow: hidden;
    }
    .tutorialContainer__1f388 {
      /* add padding on guild list after removing top bar */
      padding-top: 10px;
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
