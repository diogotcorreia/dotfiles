# Blacklist NVIDIA drivers and use integrated Intel graphics instead
{
  lib,
  pkgs,
  ...
}: {
  boot.initrd.kernelModules = ["i915"];

  hardware.nvidiaOptimus.disable = lib.mkDefault true;
  boot.blacklistedKernelModules = lib.mkDefault ["nouveau" "nvidia"];
  hardware.graphics.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];
}
