# Defines an ext4 filesystem on /nix.
# Additionally, mount a tmpfs system on root (/).
# Due to disko, this allows the partitions to be declaratively
# created when the host is first setup.
{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (config.my.filesystem) espSize;
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

  # Persist certain data across reboots
  modules.impermanence = {
    enable = true;
    persistDirectory = "/nix/persist";
  };

  # Partitions configuration (using disko)
  disko.devices = {
    disk = {
      # Define disk with two partitions, one EFI boot partition
      # and another ext4 taking up the remaining of the disk space.
      # If using legacy boot, create an additional partition for GRUB.
      disk0 = {
        type = "disk";
        device = config.my.filesystem.mainDisk;
        content = {
          type = "gpt";
          partitions =
            (lib.optionalAttrs (!config.my.filesystem.useEfi) {
              boot = {
                size = "1M";
                type = "EF02"; # for grub MBR
              };
            })
            // {
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
                  mountpoint = "/nix";
                };
              };
            };
        };
      };
    };
    nodev = {
      # https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=1G"
          "mode=755"
        ];
      };
    };
  };
}
