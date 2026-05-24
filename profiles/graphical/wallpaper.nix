# Changes wallpapers based on time of day
{
  pkgs,
  lib,
  configDir,
  ...
}:
let
  wallpapers = [
    {
      startTime = "00:00";
      path = "${configDir}/wallpapers/midnight-wallpaper.png";
    }
    {
      startTime = "06:30";
      path = "${configDir}/wallpapers/morning-wallpaper.png";
    }
    {
      startTime = "14:00";
      path = "${configDir}/wallpapers/noon-wallpaper.jpg";
    }
    {
      startTime = "19:30";
      path = "${configDir}/wallpapers/night-wallpaper.png";
    }
  ];
  wallpaperScript = pkgs.writeShellScriptBin "setbg" ''
    now=$(${lib.getExe' pkgs.coreutils "date"} +%s)
    ${lib.strings.concatMapStringsSep "\n" (wallpaper: ''
      if [[ `${lib.getExe' pkgs.coreutils "date"} --date='${wallpaper.startTime}' +%s` -le "$now" ]]; then
        chosen_wallpaper='${wallpaper.path}'
      fi
    '') wallpapers}

    if [ -n "$chosen_wallpaper" ]; then
    ${lib.getExe pkgs.awww} img "$chosen_wallpaper"
    fi
  '';
in
{
  hm.services.awww.enable = true;

  hm.systemd.user.services.set-wallpaper = {
    Unit = {
      Description = "Set desktop background";
      After = [
        "graphical-session.target"
        "awww.service"
      ];
      PartOf = [ "graphical-session.target" ];
      Requires = [ "awww.service" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe wallpaperScript;
      IOSchedulingClass = "idle";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  hm.systemd.user.timers.set-wallpaper = {
    Unit = {
      Description = "Set desktop background";
    };

    Timer = {
      OnCalendar = lib.catAttrs "startTime" wallpapers;
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  hm.home.packages = [ wallpaperScript ];
}
