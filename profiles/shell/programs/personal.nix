# global programs and packages
{pkgs, ...}: {
  # Non-essential packages (for personal systems)
  environment.systemPackages = with pkgs; [
    # Nix formatter
    alejandra

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

    # Other utilities
    # TODO 25.11: replace with wcurl when it releases (curl 8.14.0)
    wget

    # Agenix
    agenix
  ];

  environment.shellAliases = {
    neofetch = "fastfetch";
  };
}
