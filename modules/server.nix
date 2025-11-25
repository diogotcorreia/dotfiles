# Common configuration for servers
{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.server;
in
{
  options.modules.server = {
    enable = mkEnableOption "server common configuration";
  };

  config = mkIf cfg.enable {
    age.secrets.autoUpgradeHealthchecksUrl.file = secrets.host.autoUpgradeHealthchecksUrl;

    my.autoUpgrade = {
      enable = true;
      operation = "switch";

      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
      allowReboot = true;
      flags = [
        # Prevent building on local machine (always fetch from cache)
        "--max-jobs"
        "0"
        "--cores"
        "1"
      ];

      dates = "04:00";
      randomizedDelaySec = "1h";
    };

    modules.services.healthchecks.systemd-monitoring = {
      # must match service of my.autoUpgrade
      nixos-upgrade.checkUrlFile = config.age.secrets.autoUpgradeHealthchecksUrl.path;
    };

    nix.optimise.automatic = true;
    nix.gc = {
      automatic = true;
      options = "-d"; # delete old generations

      dates = "weekly";
      randomizedDelaySec = "2h";
    };
    hm.nix.gc = {
      automatic = true;
      options = "-d"; # delete old generations

      dates = "weekly";
    };
  };
}
