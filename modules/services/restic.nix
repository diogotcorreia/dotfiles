# append-only restic backups configuration with healthchecks ping.
{
  config,
  lib,
  pkgs,
  secrets,
  utils,
  ...
}:
let
  inherit (lib)
    mkBefore
    mkEnableOption
    mkOption
    types
    mkIf
    optionalAttrs
    ;
  inherit (lib.strings) optionalString;
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.modules.services.restic;
in
{
  options.modules.services.restic = {
    enable = mkEnableOption "restic";

    paths = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = lib.mdDoc ''
        Which paths to backup. If null or an empty array, no
        backup command will be run. This can be used to create a
        prune-only job.
      '';
      example = [
        "/var/lib/postgresql"
        "/home/user/backup"
      ];
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = lib.mdDoc ''
        Patterns to exclude when backing up.
      '';
      example = [
        "/var/cache"
        "/home/*/.cache"
        ".git"
      ];
    };

    timerConfig = mkOption {
      type = types.attrsOf unitOption;
      default = {
        OnCalendar = "daily";
      };
      description = lib.mdDoc ''
        When to run the backup. See man systemd.timer for details.
      '';
      example = {
        OnCalendar = "00:05";
        RandomizedDelaySec = "5h";
      };
    };

    backupPrepareCommand = mkOption {
      type = with types; nullOr lines;
      default = null;
      description = lib.mdDoc ''
        A script that must run before starting the backup process.
      '';
    };

    backupCleanupCommand = mkOption {
      type = with types; nullOr lines;
      default = null;
      description = lib.mdDoc ''
        A script that must run after finishing the backup process.
      '';
    };

    stdinFromCommand = mkOption {
      description = "A list of commands whose output should be backed up";
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            fileName = mkOption {
              type = types.nullOr types.str;
              description = "The name of the file the output is stored as in the backup";
              default = null;
              example = "backup.sql";
            };
            tags = mkOption {
              type = types.listOf types.str;
              description = "The tags to assign to this backup";
              default = [ ];
              example = [ "postgresql" ];
            };
            command = mkOption {
              type = types.listOf types.str;
              description = "A command and its arguments";
              example = [ "pg_dumpall" ];
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable (
    let
      resticName = "systemBackup";
      # must match the restic module config
      # https://github.com/NixOS/nixpkgs/blob/660e7737851506374da39c0fa550c202c824a17c/nixos/modules/services/backup/restic.nix#L294
      systemdServiceName = "restic-backups-${resticName}";

      # group by host,tags instead of host,paths
      groupByOptions = [ "--group-by=host,tags" ];

      resticCfg = config.services.restic.backups.${resticName};

      commonBackupArgs = groupByOptions;
    in
    {
      age.secrets = {
        resticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
        resticPassword.file = secrets.host.resticPassword;
        resticSshConfig.file = secrets.host.resticSshConfig;
        resticSshKey.file = secrets.host.resticSshKey;
      };

      services.restic.backups.${resticName} = {
        repository = "rclone:";
        extraOptions =
          let
            configOpt = "-F ${config.age.secrets.resticSshConfig.path}";
            keyOpt = "-i ${config.age.secrets.resticSshKey.path}";
            otherOpt = "-o VerifyHostKeyDNS=yes";
          in
          [
            # The remote has an authorized_keys file with the following format:
            # command="rclone serve restic --stdio --append-only ./restic" ssh-ed25519 ...
            # The SSH config should have the following format:
            # Host backupserver
            #   HostName <...>
            #   Port <...>
            #   User <...>
            "rclone.program=${lib.escapeShellArg "ssh ${configOpt} ${keyOpt} ${otherOpt} backupserver forced-command"}"
          ];
        passwordFile = config.age.secrets.resticPassword.path;

        user = "restic";
        package = pkgs.restic-without-rclone;

        paths = cfg.paths ++ [
          "/var/lib/nixos" # contains uid/gid map, required for restoring
        ];
        exclude = cfg.exclude;
        extraBackupArgs = commonBackupArgs ++ [ "--tag=files" ];
        checkOpts = [
          # ensure data integrity
          "--read-data-subset=2.5%"
        ];
        timerConfig = cfg.timerConfig;

        # Healthchecks configuration
        backupPrepareCommand = ''
          set -e -o pipefail
          ${optionalString (cfg.backupPrepareCommand != null) ''
            ${cfg.backupPrepareCommand}
          ''}
        '';
        backupCleanupCommand = cfg.backupCleanupCommand;
      };

      systemd.services.${systemdServiceName} = {
        # Only run when network is up
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        # Execute additional backups from stdin
        serviceConfig.ExecStart = mkBefore (
          map (
            stdinCmd:
            let
              tagsArgs = lib.concatMapStrings (arg: " --tag ${lib.escapeShellArg arg}") stdinCmd.tags;
              filenameArg = optionalString (
                stdinCmd.fileName != null
              ) " --stdin-filename ${lib.escapeShellArg stdinCmd.fileName}";
              stdinArg = " --stdin-from-command -- ${lib.escapeShellArgs stdinCmd.command}";

              backupArgs = lib.concatStringsSep " " commonBackupArgs;
              extraOptions = lib.concatMapStrings (arg: " -o ${arg}") resticCfg.extraOptions;
              resticCmd = "${lib.getExe resticCfg.package}${extraOptions}";
            in
            "${resticCmd} backup ${backupArgs}${tagsArgs}${filenameArg}${stdinArg}"
          ) cfg.stdinFromCommand
        );

        # Allow unit to read all files in the system
        serviceConfig.AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
      }
      // optionalAttrs (config.modules.personal.enable) {
        # Configure backups for personal machines
        # Only on AC (for laptops) and never more frequently than 12h
        startLimitIntervalSec = 12 * 60 * 60; # 12h
        startLimitBurst = 1;
        unitConfig.ConditionACPower = "|true"; # | means trigger
      };

      modules.services.healthchecks.systemd-monitoring.${systemdServiceName}.checkUrlFile =
        config.age.secrets.resticHealthchecksUrl.path;

      users.users.restic = {
        group = "restic";
        isSystemUser = true;
      };
      users.groups.restic = { };
    }
  );
}
