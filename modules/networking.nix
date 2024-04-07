# Network configuration
{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.my.networking = {
    wiredInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "eth0";
      description = "The main wired interface of this device";
    };
    wirelessInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "wlo1";
      description = "The main wireless interface of this device";
    };
  };
}
