# NFS mount of Synology diskstation (NAS)
{...}: let
  diskstationAddress = "192.168.1.4";
in {
  # For NFS to work correctly, users have to share the same UID/GID in this
  # server and in the NAS.
  # However, Synology's DSM does not have an easy way to create a user with
  # a specific UID/GID, therefore workarounds are needed.
  # First, create a normal user through the UI.
  # Secondly, edit `/etc/passwd` and `/etc/group` and change the UID/GID there.
  # Then, run `sudo synouser --rebuild all` to make the changes permanent.
  # Finally, fix the ACL rules with `synoacltool`.

  # NAS mounts
  fileSystems."/mnt/diskstation" = {
    device = "${diskstationAddress}:/volume1/hera";
    fsType = "nfs";
    options = let
      # Prevents hanging on network split, and only mounts when accessed
      automount = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=600"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
      ];
    in
      automount;
  };

  # Cannot use FS-Cache because the host uses ZFS as the file system :(
}
