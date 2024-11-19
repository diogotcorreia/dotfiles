# Enable (proprietary :/) NVIDIA drivers
{config, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # GTX 1050Ti is not supported by open-source drivers
    # https://github.com/NVIDIA/open-gpu-kernel-modules/issues/19
    open = false;

    modesetting.enable = true;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
