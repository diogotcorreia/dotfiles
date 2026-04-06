{ ... }:
{
  hm.programs.ghostty = {
    enable = true;
    systemd.enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      window-decoration = "server";
      background-opacity = 0.75;
      theme = "light:Nord Light,dark:Nord";
    };
  };
}
