# hosts/bacchus/home.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Home configuration for bacchus (PC).

{ pkgs, ... }: {
  modules = {
    dwm.enable = true;
    lf.enable = true;
    zsh.enable = true;
    neovim.enable = true;
    shell = {
      git.enable = true;
      tmux.enable = true;
    };
  };

  home.stateVersion = "22.11";
}
