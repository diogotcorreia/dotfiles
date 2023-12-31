# modules/services/healthchecks.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# healthchecks ping configuration.

{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkEnableOption mkOption types mkIf recursiveUpdate mapAttrs' optionalString
    mkBefore mkAfter nameValuePair;
  cfg = config.modules.services.healthchecks;
in {
  options.modules.services.healthchecks = {
    enable = mkEnableOption "healthchecks";
    checkUrlFile = mkOption {
      type = types.path;
      default = "/dev/null";
      example = "config.age.secrets.healthchecksUrl.path";
      description =
        "A file containing the URL to ping. It's recommended to keep this secret to avoid others pinging the URL.";
    };
    timerExpression = mkOption {
      type = types.str;
      default = "*-*-* *:*:00"; # every minute
      example = "*:5/10"; # every 5 minutes
      description =
        "A system timer expression to control when the URL is pinged. https://www.freedesktop.org/software/systemd/man/systemd.time.html";
    };

    systemd-monitoring = mkOption {
      description =
        "Systemd services to wrap with healthcheck start, failure and finish pings";
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          checkUrlFile = mkOption {
            type = types.path;
            default = "/dev/null";
            example = "config.age.secrets.healthchecksUrl.path";
            description =
              "A file containing the URL to ping. It's recommended to keep this secret to avoid others pinging the URL.";
          };
        };
      }));
      default = { };
      example = {
        restic-backups-systemBackup.checkUrlFile =
          "config.age.secrets.healthchecksUrl.path";
      };
    };
  };

  config = let
    getHealthchecksCmd = urlFile: type: ignoreErrors: ''
      ${pkgs.bash}/bin/bash -c '${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null $(${pkgs.coreutils}/bin/cat ${urlFile})${
        optionalString (type != null) "/${type}"
      }${optionalString ignoreErrors " || true"}'
    '';

    # https://www.freedesktop.org/software/systemd/man/systemd.exec.html#%24EXIT_CODE
    mkStopScript = url:
      pkgs.writeShellScript "healthchecks-stop" ''
        if [[ "$SERVICE_RESULT" == "success" && "$EXIT_STATUS" == "0" ]]; then
          ${getHealthchecksCmd url null false}
        elif [[ "$SERVICE_RESULT" != "start-limit-hit" ]]; then
          ${getHealthchecksCmd url "fail" false}
        fi
      '';

    systemd-services = mapAttrs' (name: options:
      nameValuePair name {
        preStart =
          mkBefore (getHealthchecksCmd options.checkUrlFile "start" true);
        postStop = mkAfter "${mkStopScript options.checkUrlFile}";
      }) cfg.systemd-monitoring;

  in {
    systemd.services = (if cfg.enable then {
      ping-healthchecks = {
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = getHealthchecksCmd cfg.checkUrlFile null false;
        };
      };
    } else
      { }) // systemd-services;

    systemd.timers = if cfg.enable then {
      ping-healthchecks = {
        wantedBy = [ "timers.target" ];
        timerConfig = { OnCalendar = cfg.timerExpression; };
      };
    } else
      { };
  };
}
