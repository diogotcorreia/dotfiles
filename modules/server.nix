# modules/server.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Common configuration for servers.
{
  config,
  lib,
  systemFlakePath,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption optionalAttrs types;
  cfg = config.modules.server;
in {
  options.modules.server = {
    enable = mkEnableOption "server common configuration";
    autoUpgradeCheckUrlFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "config.age.secrets.autoUpgradeHealthchecksUrl.path";
      description = "A file containing the URL to ping. It's recommended to keep this secret to avoid others pinging the URL.";
    };
  };

  config = mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = systemFlakePath;
      operation = "switch";

      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
      allowReboot = true;
      flags = [
        # Only use one job to avoid running out of memory and disrupting operations
        "--max-jobs"
        "1"
      ];

      dates = "04:00";
      randomizedDelaySec = "1h";
    };

    modules.services.healthchecks.systemd-monitoring =
      optionalAttrs
      (config.system.autoUpgrade.enable
        && cfg.autoUpgradeCheckUrlFile
        != null) {
        # must match service of system.autoUpgrade
        # https://github.com/NixOS/nixpkgs/blob/9dd7699928e26c3c00d5d46811f1358524081062/nixos/modules/tasks/auto-upgrade.nix#L175
        nixos-upgrade.checkUrlFile = cfg.autoUpgradeCheckUrlFile;
      };

    nix.optimise.automatic = true;
    nix.gc = {
      automatic = true;
      options = "-d"; # delete old generations

      dates = "weekly";
      randomizedDelaySec = "15min";
    };
  };
}
