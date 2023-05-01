# modules/programs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# global programs and packages

{ pkgs, agenixPackage, ... }: {
  # Essential packages
  environment.systemPackages = with pkgs; [
    # Compressed archives
    atool
    zip
    unzip

    # Editors
    neovim

    # Terminal multiplexers
    tmux

    # Nix formatter
    nixfmt

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
    agenixPackage
  ];
}
