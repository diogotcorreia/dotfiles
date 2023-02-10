# modules/programs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# global programs and packages

{ pkgs, config, lib, agenixPackage, ... }: {
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

    # Agenix
    agenixPackage
  ];
}
