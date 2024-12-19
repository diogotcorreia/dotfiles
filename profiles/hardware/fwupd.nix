# https://wiki.nixos.org/wiki/Fwupd
# Enable daemon to perform firmware/UEFI updates
{...}: {
  services.fwupd.enable = true;
}
