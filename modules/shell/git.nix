# Git configuration. (Based on RageKnify's)
{
  lib,
  config,
  configDir,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.shell.git;
in
{
  options.modules.shell.git.enable = mkEnableOption "git";

  config.hm = mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user.name = "Diogo Correia";
        user.email = "me@diogotc.com";
        diff.tool = "vimdiff";
        init.defaultBranch = "master";
        pull.rebase = true;
        url."git@github.com:".pushinsteadOf = "https://github.com/";
        commit.template = "${configDir}/gitmessage.txt";
        commit.verbose = true;
        rerere.enabled = true;
      };
      signing = {
        key = lib.mkDefault null;
        signByDefault = lib.mkDefault (config.home-manager.users.${user}.programs.git.signing.key != null);
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
    programs.delta = {
      enable = config.modules.personal.enable;
      enableGitIntegration = true;
      options = {
        features = "decorations";
        line-numbers = true;
        # Workaround for https://github.com/dandavison/delta/issues/1663
        dark = true;
      };
    };
  };
}
