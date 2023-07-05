# modules/personal.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# non-graphical configuration for personal computers.

{ pkgs, config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;
in {
  options.modules.personal.enable = mkEnableOption "personal";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # dog DNS CLI client (dig alternative)
      dogdns
      # qalc (CLI calculator)
      libqalculate
      # LaTeX
      texlive.combined.scheme-small
      texlab
      # Nix Index (provides nix-locate to locate files in the Nix store)
      nix-index
      # timewarrior (time tracker)
      timewarrior
      # Rust
      rustup
    ];
    modules.services.restic.paths =
      [ "${config.my.homeDirectory}/.timewarrior" ];

    hm.programs.zsh.shellAliases."dig" = "${pkgs.dogdns}/bin/dog";

    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    hm.programs.git.ignores = [ ".envrc" ".direnv" ];

    # Android Debug Bridge
    usr.extraGroups = [ "adbusers" ];
    programs.adb.enable = true;

    # ssh client config
    hm.programs.ssh = {
      enable = true;
      matchBlocks = {
        "* !apollo !bacchus !ceres".setEnv = { TERM = "xterm-256color"; };

        apollo = {
          hostname = "192.168.100.2";
          user = "dtc";
        };
        bacchus = {
          hostname = "192.168.100.3";
          user = "dtc";
        };
        ceres = {
          hostname = "192.168.100.4";
          user = "dtc";
        };

        artemis = {
          hostname = "artemis.diogotc.com";
          user = "dtc";
        };
        hades = {
          hostname = "hades.pedropirescoaching.com";
          user = "dtc";
        };
        hera = {
          hostname = "192.168.100.5";
          user = "dtc";
        };
        phobos = {
          hostname = "phobos.diogotc.com";
          user = "dtc";
        };
        poseidon = {
          hostname = "mail.lpespaco.pt";
          user = "dtc";
        };
        zeus = {
          hostname = "mail.diogotc.com";
          user = "dtc";
        };

        sigma = {
          # use a specific server instead of load balancer for kerberos to work
          hostname = "sigma02.tecnico.ulisboa.pt";
          user = "ist199211";

          extraOptions = {
            GSSAPIAuthentication = "yes";
            GSSAPIDelegateCredentials = "yes";
          };
        };
        hs = {
          hostname = "server.hackerschool.io";
          user = "dtc";
        };
      };
    };

    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
      '';
    };
  };
}
