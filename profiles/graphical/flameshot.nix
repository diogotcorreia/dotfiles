{ lib, ... }:
{
  hm.services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        savePath = "/tmp";
        savePathFixed = false;
        saveAsFileExtension = ".png";
        uiColor = "${lib.my.colors.lightblue}";
        startupLaunch = false;
        antialiasingPinZoom = true;
        uploadWithoutConfirmation = false;
        predefinedColorPaletteLarge = true;
        useGrimAdapter = true;
      };
    };
  };
}
