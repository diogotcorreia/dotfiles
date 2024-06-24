# Libvirt configuration
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
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
