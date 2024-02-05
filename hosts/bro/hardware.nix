# the default hardware config can be generated with `nixos-generate-config --show-hardware-config`
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  # a host id can be generated with `head -c4 /dev/urandom | od -A none -t x4`
  hostId = "29e7efc9";

  diskDevice = "/dev/sda";
  espSize = "512M";
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  boot.supportedFilesystems = ["zfs"];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode =
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

  # Persistence (root dataset is rollback'ed to a blank snapshot)
  networking.hostId = hostId;
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';

  # Zram Swap
  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };
}
