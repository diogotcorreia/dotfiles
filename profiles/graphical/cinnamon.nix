{ ... }:
{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
      cinnamon.enable = true;
    };
    displayManager.lightdm.enable = true;
  };
  services.displayManager.defaultSession = "cinnamon";
  xdg.portal.enable = true;

  modules.impermanence.directories = [
    "/etc/NetworkManager/system-connections"
    "/var/lib/AccountsService"
  ];
}
