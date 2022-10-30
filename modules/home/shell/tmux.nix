# modules/home/shell/tmux.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# tmux configuration (Based on RageKnify's)

{ config, lib, colors, hostColor, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.tmux;
in {
  options.modules.shell.tmux.enable = mkEnableOption "tmux";

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      customPaneNavigationAndResize = true;
      escapeTime = 0;
      extraConfig = ''
        set -g terminal-overrides ",gnome*:RGB"
        # Set status bar color
        set -g status-style fg='${colors.light.base07}',bg='${hostColor}'

        # set status line
        set -g status-left '#[bold][#S]  '
        set -g status-left-length 10
        set -g status-right '#[bold]#h  '
        set -g status-right-length 10
        set -g window-status-style bold

        # New panes/windows are always opened in the current working directory
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Enable mouse
        set -g mouse on

        # Enable osc-52
        set -g set-clipboard on
      '';
      historyLimit = 50000;
      keyMode = "vi";
      terminal = "tmux-256color";
    };
  };
}
