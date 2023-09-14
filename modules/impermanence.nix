# modules/impermanence.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Wrapper around nix-community/impermanence to allow shared configs
# between hosts with and without ephemeral root storage

{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkEnableOption mkIf;
  cfg = config.modules.impermanence;

  persistDirectory = "/persist";
in {
  options.modules.impermanence = {
    enable = mkEnableOption "Enable impermanence module";

    files = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Files that should be stored in persistent storage.
      '';
    };
    directories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Directories to bind mount to persistent storage.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.persistence.${persistDirectory} = {
      directories = cfg.directories ++ [ "/var/lib/systemd" "/var/log" ];
      files = cfg.files ++ [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    };
  };
}
