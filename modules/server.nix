# modules/server.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Common configuration for servers.

{ config, lib, systemFlakePath, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.server;
in {
  options.modules.server.enable = mkEnableOption "server common configuration";

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

      dates = "04:00";
      randomizedDelaySec = "1h";
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
