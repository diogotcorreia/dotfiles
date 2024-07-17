# Defines an ext4 standard filesystem.
# Due to disko, this allows the partitions to be declaratively
# created when the host is first setup.
{
  config,
  inputs,
  ...
}: let
  espSize = "512M";
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  assertions = [
    {
      assertion = config.my.filesystem.mainDisk != null;
      message = ''
        Declaring a filesystem requires my.filesystem.mainDisk to be set
      '';
    }
  ];

  # Partitions configuration (using disko)
  disko.devices = {
    disk = {
      # Define disk with two partitions, one EFI boot partition
      # and another ext4 taking up the remaining of the disk space.
      disk0 = {
        type = "disk";
        device = config.my.filesystem.mainDisk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = espSize;
              type = "EF00"; # for EFI boot
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
