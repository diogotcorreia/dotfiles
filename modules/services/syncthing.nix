# modules/services/syncthing.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# syncthing configuration

{ pkgs, config, lib, utils, user, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.services.syncthing;
in {
  options.modules.services.syncthing.enable = mkEnableOption "syncthing";

  config = mkIf cfg.enable {
    services.syncthing = {
      inherit user;
      enable = true;
      systemService = true;
      dataDir = "${config.my.homeDirectory}/.syncthing";
      overrideFolders = false;
      overrideDevices = false;
      extraOptions = { gui = { theme = "dark"; }; };
    };
  };
}
