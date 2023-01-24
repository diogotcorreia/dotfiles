# hosts/bacchus/home.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Home configuration for bacchus (PC).

{ pkgs, ... }: {
  modules = {
    cybersec.enable = true;
    graphical.brave.enable = true;
    graphical.development.enable = true;
    graphical.dwm.enable = true;
    graphical.programs.enable = true;
    graphical.spotify.enable = true;
    graphical.zathura.enable = true;
    lf.enable = true;
    neovim.enable = true;
    personal.enable = true;
    shell = {
      git.enable = true;
      tmux.enable = true;
    };
    zsh.enable = true;
  };

  home.packages = with pkgs;
    [
      # Karaoke Game
      ultrastardx
    ];

  home.stateVersion = "22.11";
}
