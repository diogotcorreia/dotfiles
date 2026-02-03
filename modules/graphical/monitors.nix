# Monitor configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.my.graphical = {
    monitors = mkOption {
      description = "A list of monitors present in this device";
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the connector of the monitor";
              example = "eDP-1";
            };
            primary = mkOption {
              type = types.bool;
              description = "Whether this is the primary monitor of the device";
              default = false;
              example = true;
            };
            position = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    x = mkOption {
                      type = types.int;
                      example = 1280;
                    };
                    y = mkOption {
                      type = types.int;
                      example = 0;
                    };
                  };
                }
              );
              description = "The virtual position of this monitor. If left null, they will be positioned automatically";
              default = null;
            };
          };
        }
      );
    };
    monitorDirection = mkOption {
      description = "The direction the monitors are layed out";
      type = types.enum [
        "horizontally"
        "vertically"
      ];
      example = "horizontally";
    };
    primaryMonitor = mkOption {
      description = "The name of the primary monitor of this device";
      type = types.nullOr types.str;
      readOnly = true;
      default = (lib.findFirst (m: m.primary) { name = null; } config.my.graphical.monitors).name;
    };
  };

  config = {
    assertions = [
      {
        assertion =
          config.my.graphical.monitors != [ ]
          -> lib.length (lib.filter (m: m.primary) config.my.graphical.monitors) == 1;
        message = "`my.graphical.monitors` must have exactly one primary monitor.";
      }
    ];
  };
}
