# modules/services/healthchecks.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# healthchecks ping configuration.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
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
  };

  config = mkIf cfg.enable {
    systemd.services.healthchecks = {
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.bash}/bin/bash -c '${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null $(${pkgs.coreutils}/bin/cat ${cfg.checkUrlFile})'";
      };
    };

    systemd.timers.healthchecks = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnCalendar = cfg.timerExpression; };
    };
  };
}
