# hosts/phobos/home.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Home configuration for phobos (server).

{ pkgs, ... }: {
  modules = {
    lf.enable = true;
    zsh.enable = true;
    neovim.enable = true;
    shell = {
      git.enable = true;
      tmux.enable = true;
    };
  };

  home.stateVersion = "21.11";
}
