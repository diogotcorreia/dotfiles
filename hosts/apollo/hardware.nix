# the default hardware config can be generated with `nixos-generate-config --show-hardware-config`
{
  config,
  lib,
  modulesPath,
  ...
}: let
  # a host id can be generated with `head -c4 /dev/urandom | od -A none -t x4`
  hostId = "30c1f688";

  diskDevice = "/dev/nvme0n1";
  espSize = "512M";
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  boot.supportedFilesystems = ["zfs"];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Partitions configuration (using disko)
  disko.devices = {
    disk = {
      disk0 = {
        type = "disk";
        device = diskDevice;
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

        datasets = {
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            mountOptions = ["zfsutil"];

            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            mountOptions = ["zfsutil"];
          };
          # To be used in emergencies if the disk goes full
          "local/reserved" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              refreservation = "1G";
            };
          };
          "safe/persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            mountOptions = ["zfsutil"];
          };
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

  # External Drive
  fileSystems."/media/files" = {
    device = "/dev/disk/by-uuid/7257ad05-1068-4545-936b-94231db82bb1";
    fsType = "ext4";
  };

  # Persistence (root dataset is rollback'ed to a blank snapshot)
  networking.hostId = hostId;
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';
}
