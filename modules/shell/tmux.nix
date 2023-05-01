# modules/home/shell/tmux.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# tmux configuration (Based on RageKnify's)

{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux.enable = mkEnableOption "tmux";

  # Home manager module
  config.hm = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      customPaneNavigationAndResize = true;
      escapeTime = 0;
      extraConfig = ''
        # Tell tmux the terminal supports RGB colors
        set -g terminal-overrides ",gnome*:RGB"

        # New panes/windows are always opened in the current working directory
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Enable mouse
        set -g mouse on

        # Enable osc-52
        set -g set-clipboard on

        # Use Nord theme
        run-shell "${pkgs.unstable.tmuxPlugins.nord}/share/tmux-plugins/nord/nord.tmux"
      '';
      historyLimit = 50000;
      keyMode = "vi";
      terminal = if config.modules.graphical.programs.enable then
        "alacritty"
      else
        "tmux-256color";
    };
  };
}
