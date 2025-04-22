# global programs and packages
{pkgs, ...}: {
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

    # Agenix
    agenix
  ];
}
