# global programs and packages
{pkgs, ...}: {
  # Essential packages
  environment.systemPackages = with pkgs; [
    # Compressed archives
    atool
    zip
    unzip

    # Terminal multiplexers
    tmux

    # Nix formatter
    alejandra

    # System monitor
    htop
    procps
    gdu
    duf

    # Neofetch
    neofetch

    # Man pages
    man-pages

    # Find and search files
    fzf
    ripgrep

    # perl-rename (much better than the one from util-linux)
    rename

    # Other utilities
    wget

    # Agenix
    agenix
  ];
}
