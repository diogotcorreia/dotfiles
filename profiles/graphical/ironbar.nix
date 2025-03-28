{
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  generateCfg = jsonFormat.generate "ironbar-config";

  pkg = pkgs.my.ironbar-unstable;
in {
  hm.home.packages = [pkg];

  hm.xdg.configFile."ironbar/config.json".source = generateCfg {
    position = "top";
    height = 29;
    start = [
      {
        type = "workspaces";
      }
      {
        type = "focused";
        truncate = "end";
      }
    ];
    center = [
    ];
    end = [
      {
        type = "volume";
      }
      {
        type = "upower";
        format = "{percentage}% ({time_remaining})";
      }
      {
        type = "network_manager";
      }
      {
        type = "clock";
        format = "%Y %b %d (%a) %H:%M:%S";
      }
    ];
  };

  hm.xdg.configFile."ironbar/style.css".text = ''
  '';

  hm.systemd.user.services.ironbar = {
    Unit = {
      Description = "Systemd service for Ironbar";
      Requires = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = lib.getExe pkg;
    };

    Install.WantedBy = [
      "graphical-session.target"
    ];
  };

  # Enable Upower for battery widget
  services.upower.enable = true;
}
