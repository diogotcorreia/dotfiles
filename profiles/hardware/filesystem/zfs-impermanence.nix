# Defines a ZFS filesystem that gets rolled back to a blank
# snapshot on boot.
# Due to disko, this allows the partitions to be declaratively
# created when the host is first setup.
{
  config,
  inputs,
  lib,
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

  # Enable ZFS kernel packages/modules
  boot.supportedFilesystems = ["zfs"];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # Enable services to maintain the ZFS pool
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Persist certain data across reboots
  modules.impermanence.enable = true;

  # Partitions configuration (using disko)
  disko.devices = {
    disk = {
      # Define disk with two partitions, one EFI boot partition
      # and another zfs pool partition taking up the remaining
      # of the disk space.
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
            rpool = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        options = {ashift = "12";};
        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "zstd";
          dnodesize = "auto";
          normalization = "formD";
          xattr = "sa";
          mountpoint = "none";
        };

        # "local" datasets are disposable and don't hold any important data.
        # "safe" datasets might contain important data that should be backed up.
        datasets = {
          # Root dataset that is not persisted across boots
          # (i.e., is rolled back to a blank state).
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            mountOptions = ["zfsutil"];

            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          # Dataset holding the nix store.
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            mountOptions = ["zfsutil"];
          };
          # To be used in emergencies if the disk goes full (i.e., by shrinking it),
          # otherwise it is always empty.
          "local/reserved" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              refreservation = "1G";
            };
          };
          # Target for the impermanence module, where all system files that should be
          # persisted between reboots are stored.
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            mountOptions = ["zfsutil"];
          };
          # Dataset that holds home directories.
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            mountOptions = ["zfsutil"];
          };
        };
      };
    };
  };

  # sadly disko can't handle this for us
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;

  # Ensure that the local/root dataset is rolled back to
  # a blank state on every boot.
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';
}
