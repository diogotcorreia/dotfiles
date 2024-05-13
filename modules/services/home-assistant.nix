{
  config,
  lib,
  ...
}: let
  inherit (lib) escapeShellArg escapeShellArgs mdDoc mkAfter mkIf mkOption types;

  cfg = config.services.home-assistant;

  quirksDir = "${cfg.configDir}/zha-quirks";
in {
  # Extend home-assistant module with extra options
  options.services.home-assistant = {
    customZhaQuirks = mkOption {
      type = types.listOf types.path;
      default = [];
      description = mdDoc ''
        List of custom ZHA (Zigbee) quirks to load.

        Available quirks can be found below `pkgs.my.home-assistant-custom-zha-quirks`.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.home-assistant.preStart = let
      copyZhaQuirks = ''
        mkdir -p ${escapeShellArg quirksDir}

        # remove quirks symlinked in from below the /nix/store
        readarray -d "" quirks < <(find ${escapeShellArg quirksDir} -maxdepth 1 -type l -print0)
        for quirk in "''${quirks[@]}"; do
          if [[ "$(readlink "$quirk")" =~ ^${escapeShellArg builtins.storeDir} ]]; then
            rm "$quirk"
          fi
        done

        # recreate symlinks for desired quirks
        declare -a quirks=(${escapeShellArgs cfg.customZhaQuirks})
        for quirk in "''${quirks[@]}"; do
          ln -fs "$quirk" ${escapeShellArg quirksDir}
        done
      '';
    in
      mkAfter copyZhaQuirks;

    services.home-assistant = {
      config = {
        zha = mkIf (cfg.customZhaQuirks != []) {
          enable_quirks = true;
          custom_quirks_path = quirksDir;
        };
      };
    };
  };
}
