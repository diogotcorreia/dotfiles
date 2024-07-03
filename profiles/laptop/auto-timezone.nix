# Enables automatic-timezoned for automatic timezone
# detection.
# Additionally, patches the included service to save
# and restore the last known timezone on boot.
{
  lib,
  pkgs,
  ...
}: {
  time.timeZone = null; # Not managed by Nix
  services.automatic-timezoned.enable = true;

  # "Hack" to save timezone before shutdown and restore
  # it during boot. Otherwise, it defaults to UTC on boot,
  # and cannot get the correct timezone until a network
  # connection is established.
  # This is only a problem on systems where the root partition
  # is not persisted. The naive approach of adding the /etc/localtime
  # file to the persisted files does not work, since it is a symlink.
  systemd.services.automatic-timezoned = {
    serviceConfig = {
      StateDirectory = "automatic-timezoned";
      StateDirectoryMode = "0755";
    };

    # Restore timezone from previous boot
    preStart = ''
      if [[ -f "$STATE_DIRECTORY/timezone" ]]; then
        timezone=$(cat "$STATE_DIRECTORY/timezone")
        if [[ -n "$timezone" ]]; then
          ${lib.getExe' pkgs.dbus "dbus-send"} --system \
            --dest=org.freedesktop.timedate1 \
            --print-reply /org/freedesktop/timedate1 \
            org.freedesktop.timedate1.SetTimezone \
            string:"$timezone" \
            boolean:false
        fi
      fi
    '';

    # Save timezone on shutdown
    postStop = ''
      if [[ "$SERVICE_RESULT" == "success" && -h /etc/localtime ]]; then
        # Can't use D-Bus here because it doesn't work on shutdown
        timezone=$(readlink /etc/localtime | sed 's/\.\.\/etc\/zoneinfo\///')
        if [[ -n "$timezone" ]]; then
          echo "$timezone" > "$STATE_DIRECTORY/timezone"
        fi
      fi
    '';
  };

  modules.impermanence.directories = ["/var/lib/automatic-timezoned"];
}
