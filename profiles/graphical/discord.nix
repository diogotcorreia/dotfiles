# Discord configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  discordThemeFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.10.23/uniform/nordic.theme.css";
    hash = "sha256-jiibjz7Z1+StWvqhXMHb3CnIjaGxNKvDQu2cjQ5VEO0=";
  };
  extraCss = ''
    .theme-dark {
      --background-primary: var(--primary-630);
      --background-secondary: var(--primary-600);
      --background-tertiary: var(--primary-700);
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
