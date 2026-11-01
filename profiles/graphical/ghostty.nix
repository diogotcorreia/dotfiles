{ ... }:
{
  hm.programs.ghostty = {
    enable = true;
    systemd.enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      window-decoration = "server";
      background-opacity = 0.85;
      theme = "light:Nord Light,dark:Nord";

      notify-on-command-finish = "unfocused";
      notify-on-command-finish-action = "bell,notify";
    };
  };
}
