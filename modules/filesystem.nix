# Options for declaring file system structure
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.my.filesystem = {
    mainDisk = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/dev/sda";
      description = "The main disk device of this host";
    };
  };
}
