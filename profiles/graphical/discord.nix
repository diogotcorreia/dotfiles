# Discord configuration
{
  config,
  pkgs,
  ...
}: let
  discordThemeFile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orblazer/discord-nordic/v4.10.21/uniform/nordic.theme.css";
    hash = "sha256-tPbKvz2PfrE4nVrEndSTUnYykRbU9PMCU9VIknSgaCE=";
  };
in {
  hm.home.packages = with pkgs; [
    # Discord
    discord-openasar
  ];

  # Discord configuration
  hm.xdg.configFile."discord/settings-override.json".text = builtins.toJSON {
    openasar = {
      setup = true;
      cmdPreset =
        if config.my.hardware.laptop
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
      '';
    };
    DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
    SKIP_HOST_UPDATE = true;
    MINIMIZE_TO_TRAY = false;
    OPEN_ON_STARTUP = false;
  };
}
