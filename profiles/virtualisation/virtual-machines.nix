# Libvirt configuration
{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";

    qemu.ovmf.enable = true; # enable UEFI
  };

  usr.extraGroups = ["libvirtd"];

  environment.systemPackages = [pkgs.virt-manager];

  # Persist virtual machines on hosts with root-on-tmpfs
  modules.impermanence.directories = ["/var/lib/libvirt"];
}
