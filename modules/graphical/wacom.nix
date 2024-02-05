# modules/graphical/wacom.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Wacom drawing tablet configuration
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.graphical.wacom;

  xsetwacom = "${pkgs.xf86_input_wacom}/bin/xsetwacom";

  setupScript = pkgs.writeShellScript "setup-wacom" ''
    for i in $(${pkgs.coreutils}/bin/seq 10); do
      if ${xsetwacom} list devices | ${pkgs.gnugrep}/bin/grep -q Wacom; then
          break
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    LIST=$(${xsetwacom} list devices)
    # FIXME: $8 is hardcoded
    PAD=$(echo "$LIST" | ${pkgs.gawk}/bin/awk '/pad/{print $8}')
    STYLUS=$(echo "$LIST" | ${pkgs.gawk}/bin/awk '/stylus/{print $8}')

    if [ -z "$PAD" ]; then
      exit 0
    fi

    ${xsetwacom} set "$STYLUS" MapToOutput ${cfg.monitor}

    ${xsetwacom} set "$PAD" Button 1 "key +ctrl z -ctrl"
    ${xsetwacom} set "$PAD" Button 2 "key +ctrl +shift p -shift -ctrl"
    ${xsetwacom} set "$PAD" Button 3 "key +ctrl +shift g -shift -ctrl"
    ${xsetwacom} set "$PAD" Button 8 "key del"
  '';
in {
  options.modules.graphical.wacom = {
    enable = mkEnableOption "wacom peripheral drivers and configuration";
    monitor = mkOption {
      type = types.str;
      default = "";
      example = "eDP-1";
      description = "Display to map drawing area to.";
    };
  };

  config = mkIf cfg.enable {
    services.xserver.wacom.enable = true;

    # Rules for triggering the systemd service when the Wacom
    # is connected by USB and Bluetooth (respectively)
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="056a", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="wacom.service"
      ACTION=="add", SUBSYSTEM=="hid", DRIVERS=="wacom", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="wacom.service"
    '';

    hm.systemd.user.services.wacom = {
      Unit = {
        Description = "Wacom setup script";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };

      Install = {WantedBy = ["graphical-session.target"];};

      Service = {
        ExecStart = "${setupScript}";
        Type = "oneshot";
      };
    };
  };
}
