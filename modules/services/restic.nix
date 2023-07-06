# modules/services/restic.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# restic backups configuration with healthchecks ping.

{ pkgs, config, lib, utils, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf optionalAttrs;
  inherit (lib.strings) optionalString;
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.modules.services.restic;
in {
  options.modules.services.restic = {
    enable = mkEnableOption "restic";

    checkUrlFile = mkOption {
      type = types.path;
      default = "/dev/null";
      example = "config.age.secrets.resticHealthchecksUrl.path";
      description = lib.mdDoc ''
        A file containing the URL to ping on start, failure and finish.
        It's recommended to keep this secret to avoid others pinging the URL.
      '';
    };

    repositoryPath = mkOption {
      type = types.str;
      default = "./restic";
      example = "./restic";
      description = lib.mdDoc ''
        Path to the restic repository inside the SFTP server.
      '';
    };

    passwordFile = mkOption {
      type = types.path;
      description = lib.mdDoc ''
        Read the repository password from a file.
      '';
      example = "config.age.secrets.resticPassword.path";
    };

    sshKeyFile = mkOption {
      type = types.path;
      description = lib.mdDoc ''
        Read the private ssh key for SFTP from a file.
      '';
      example = "config.age.secrets.resticSshKey.path";
    };

    rcloneConfigFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = lib.mdDoc ''
        Path to the file containing rclone configuration. This file
        must contain configuration for the remote "backupserver"
        and also must be readable by root.

        Example file:

        ```
        [backupserver]
        user = <username>
        host = <hostname>
        port = <port>
        ```
      '';
    };

    paths = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = lib.mdDoc ''
        Which paths to backup. If null or an empty array, no
        backup command will be run. This can be used to create a
        prune-only job.
      '';
      example = [ "/var/lib/postgresql" "/home/user/backup" ];
    };

    exclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = lib.mdDoc ''
        Patterns to exclude when backing up.
      '';
      example = [ "/var/cache" "/home/*/.cache" ".git" ];
    };

    timerConfig = mkOption {
      type = types.attrsOf unitOption;
      default = { OnCalendar = "daily"; };
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
  };

  config = mkIf cfg.enable (let
    getHealthchecksCmd = type: ''
      ${pkgs.bash}/bin/bash -c '${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null $(${pkgs.coreutils}/bin/cat ${cfg.checkUrlFile})/${type}'
    '';
    resticName = "systemBackup";
    # must match the restic module config
    # https://github.com/NixOS/nixpkgs/blob/660e7737851506374da39c0fa550c202c824a17c/nixos/modules/services/backup/restic.nix#L294
    systemdServiceName = "restic-backups-${resticName}";
    systemdFailServiceName = "${systemdServiceName}-fail";
  in {
    services.restic.backups.${resticName} = {
      repository = "rclone:backupserver:${cfg.repositoryPath}";
      rcloneConfigFile = cfg.rcloneConfigFile;
      rcloneConfig = {
        type = "sftp";
        key_file = cfg.sshKeyFile;
      };
      passwordFile = cfg.passwordFile;

      paths = cfg.paths;
      exclude = cfg.exclude;
      pruneOpts = [
        "--keep-last 20"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
        "--keep-yearly 3"
      ];
      timerConfig = cfg.timerConfig;

      # Healthchecks configuration
      backupPrepareCommand = ''
        set -e -o pipefail
        ${optionalString (cfg.backupPrepareCommand != null) ''
          ${cfg.backupPrepareCommand}
        ''}

        # allow healthchecks command to fail
        set +e +o pipefail
        ${getHealthchecksCmd "start"}
      '';
      backupCleanupCommand = cfg.backupCleanupCommand;
    };

    systemd.services.${systemdServiceName} = {
      # Healthchecks for failures
      serviceConfig.ExecStop = getHealthchecksCmd "";
      onFailure = [ "${systemdFailServiceName}.service" ];

      # Only run when network is up
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    } // optionalAttrs (config.modules.personal.enable) {
      # Configure backups for personal machines
      # Only on AC (for laptops) and never more frequently than 12h
      startLimitIntervalSec = (12 * 60 * 60); # 12h
      startLimitBurst = 1;
      unitConfig.ConditionACPower = "|true"; # | means trigger
    };
    # Healthchecks for failures
    systemd.services.${systemdFailServiceName} = {
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "backup-fail" ''
          if [[ "$MONITOR_SERVICE_RESULT" != "start-limit-hit" ]]; then
            ${getHealthchecksCmd "fail"}
          fi
        '';
      };
    };

  });
}
