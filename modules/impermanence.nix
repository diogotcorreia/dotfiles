# Wrapper around nix-community/impermanence to allow shared configs
# between hosts with and without ephemeral root storage
{
  config,
  lib,
  ...
}: let
  inherit (lib) hasPrefix isString types mkOption mkEnableOption mkIf;
  cfg = config.modules.impermanence;
in {
  options.modules.impermanence = {
    enable = mkEnableOption "Enable impermanence module";

    persistDirectory = mkOption {
      type = types.str;
      default = "/persist";
      description = "Root of persistent storage";
    };

    files = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Files that should be stored in persistent storage.
      '';
    };
    directories = mkOption {
      type = types.listOf (types.oneOf [types.str (types.attrsOf types.anything)]);
      default = [];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.persistence.${cfg.persistDirectory} = let
      parsedDirectories = map (dir:
        if isString dir && hasPrefix "/var/lib/private/" dir
        then {
          directory = dir;
          mode = "0700";
          # ensure parent dir has correct permissions
          defaultPerms.mode = "0700";
        }
        else dir)
      cfg.directories;
    in {
      directories =
        parsedDirectories
        ++ [
          "/var/lib/systemd"
          "/var/lib/nixos" # contains user/group id map
          "/var/log"
        ];
      files =
        cfg.files
        ++ [
          "/etc/machine-id"
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];
    };
  };
}
