# global programs and packages
{
  config,
  pkgs,
  ...
}:
{
  # Essential packages
  environment.systemPackages = with pkgs; [
    # Compressed archives
    atool
    zip
    unzip

    # System monitoring
    htop
    procps

    # Find and search files
    ripgrep

    # switch-to-configuration wrapper
    (pkgs.my.nixos-switch.override { hostName = config.networking.hostName; })
  ];
}
