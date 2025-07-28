# global programs and packages
{pkgs, ...}: {
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

    # Agenix
    agenix
  ];

  environment.shellAliases = {
    neofetch = "fastfetch";
    wget = "wcurl";
  };
}
