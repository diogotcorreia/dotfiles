# modules/home/shell/git.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Git configuration. (Based on RageKnify's)

{ lib, config, configDir, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.git;
in {
  options.modules.shell.git.enable = mkEnableOption "git";

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "Diogo Correia";
      userEmail = "me@diogotc.com";
      extraConfig = {
        diff.tool = "vimdiff";
        init.defaultBranch = "main";
        pull.rebase = true;
        url."git@github.com:".pushinsteadOf = "https://github.com/";
        commit.template = "${configDir}/gitmessage.txt" ;
        commit.verbose = true;
      };
      includes = [
        {
          condition = "gitdir:~/documents/dsi/";
          contents.user = {
            name = "Diogo Correia";
            email = "diogo.t.correia@tecnico.ulisboa.pt";
          };
        }
      ];
    };
  };
}
