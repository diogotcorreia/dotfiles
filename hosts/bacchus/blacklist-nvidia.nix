# hosts/bacchus/blacklist-nvidia.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Blacklist NVIDIA drivers and use integrated Intel graphics instead

{ lib, pkgs, ... }: {
  boot.initrd.kernelModules = [ "i915" ];

  hardware.nvidiaOptimus.disable = lib.mkDefault true;
  boot.blacklistedKernelModules = lib.mkDefault [ "nouveau" "nvidia" ];
  services.xserver.videoDrivers = lib.mkDefault [ "intel" ];
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];
}

