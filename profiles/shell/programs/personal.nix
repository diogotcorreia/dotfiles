# global programs and packages
{ pkgs, ... }:
{
  # Non-essential packages (for personal systems)
  environment.systemPackages = with pkgs; [
    # Nix formatter
    nixfmt-rfc-style
    nixfmt-tree

    # System monitoring
    gdu
    duf

    # Neofetch alternative
    fastfetch

    # Man pages
    man-pages

    # Find and search files
    fzf

    # perl-rename (much better than the one from util-linux)
    rename

    # CLI HTTP client
    xh

    # URL Manipulation
    trurl

    # Agenix
    agenix

    # Shell Utils
    my.shell-utils
  ];

  environment.shellAliases = {
    neofetch = "fastfetch";
    url = "trurl --json";
    wget = "wcurl";
  };
}
