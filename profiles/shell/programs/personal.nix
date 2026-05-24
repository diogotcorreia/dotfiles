# global programs and packages
{
  config,
  pkgs,
  user,
  ...
}:
{
  # Non-essential packages (for personal systems)
  environment.systemPackages = with pkgs; [
    # Nix formatter
    nixfmt
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
    # TODO: tests are failing, re-enable after https://github.com/NixOS/nixpkgs/pull/523277 is merged
    (trurl.overrideAttrs { doCheck = false; })

    # many encoding/decoding utils + ctf utils
    rsbkb

    # Agenix
    agenix

    # Shell Utils
    my.shell-utils

    # Nix utils
    nix-output-monitor
  ];

  environment.shellAliases = {
    neofetch = "fastfetch";
    url = "trurl --json";
    wget = "wcurl";
  };

  programs.nh = {
    enable = true;
    flake = "${config.users.users.${user}.home}/.dotfiles";
  };
}
