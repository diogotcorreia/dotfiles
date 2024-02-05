# modules/virtual-machines.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Libvirt configuration.
{
  pkgs,
  config,
  lib,
  secretsDir,
  ...
}: let
  inherit (lib) mkEnableOption mkIf escapeShellArg getAttr attrNames;
  cfg = config.modules.virtual-machines;
in {
  options.modules.virtual-machines.enable = mkEnableOption "libvirt";

  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
    };

    usr.extraGroups = ["libvirtd"];

    environment.systemPackages = [pkgs.virt-manager];

    # Persist virtual machines on hosts with root-on-tmpfs
    modules.impermanence.directories = ["/var/lib/libvirt"];
  };
}
