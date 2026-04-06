{ pkgs, ... }:
{
  imports = [
    ./aliases
  ];

  hm = {
    programs.fish = {
      enable = true;
      # Disable fish greeting and set theme
      shellInit = /* fish */ ''
        set -g fish_greeting

        set fish_color_command green
        set fish_color_param normal
        set fish_color_comment brblack
      '';
    };

    # eza (modern ls replacement)
    programs.eza.enable = true;
    # starship (shell theme)
    programs.starship.enable = true;
    # zoxide (jump to directories)
    programs.zoxide.enable = true;
    home.sessionVariables._ZO_ECHO = "1";

    programs.starship.settings = {
      scan_timeout = 1;
      add_newline = true;

      username.format = "[$user]($style) in ";
      hostname = {
        ssh_only = true;
        format = "[$hostname]($style) ";
      };
    };
  };

  usr.shell = pkgs.fish;

  programs.fish.enable = true;
}
