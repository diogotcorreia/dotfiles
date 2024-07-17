# Options for declaring file system structure
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.my.filesystem = {
    espSize = mkOption {
      type = lib.types.strMatching "[0-9]+[KMGTP]?";
      default = "512M";
      example = "128M";
      description = "The size of the boot partition";
    };
    useEfi = mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Whether to create/use an EFI partition (if true) or a legacy BIOS partition (if false)";
    };
    mainDisk = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/dev/sda";
      description = "The main disk device of this host";
    };
  };
}
