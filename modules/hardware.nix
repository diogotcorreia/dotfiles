# Hardware configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.my.hardware;
in
{
  options.my.hardware = {
    batteryPowered = mkOption {
      type = types.bool;
      default = cfg.laptop;
      description = "Whether this device is battery-powered (e.g., a laptop)";
    };
    laptop = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this device is a laptop";
    };
  };
}
