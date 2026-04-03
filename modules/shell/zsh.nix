# zsh (with oh-my-zsh) configuration.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.zsh;
in
{
  options.modules.shell.zsh.enable = mkEnableOption "zsh";

  # Home manager module
  config = mkIf cfg.enable {
    hm = {
      programs.zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          plugins = [
            "git"
            "docker-compose"
            "zoxide"
          ];
        };
        plugins = [
          {
            name = "zsh-autosuggestions";
            inherit (pkgs.zsh-autosuggestions) src;
          }
          {
            name = "zsh-completions";
            inherit (pkgs.zsh-completions) src;
          }
          {
            name = "zsh-syntax-highlighting";
            inherit (pkgs.zsh-syntax-highlighting) src;
          }
        ];
        # FIXME this isn't working correctly on neovim.nix
        initContent = ''
          export EDITOR=nvim
        '';
      };

      # eza (modern ls replacement)
      programs.eza.enable = true;
      programs.eza.enableZshIntegration = true;
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

    programs.zsh.enable = true;
  };
}
