# non-graphical configuration for personal computers.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.personal;
in
{
  options.modules.personal.enable = mkEnableOption "personal";

  config = mkIf cfg.enable {
    hm.home.packages = with pkgs; [
      # dog DNS CLI client (dig alternative)
      dogdns
      # json manipulator
      jq
      # qalc (CLI calculator)
      libqalculate
      # timewarrior (time tracker) + hook for updating waybar widget
      (pkgs.writeShellScriptBin "timew" ''
        callback() {
          pkill -SIGRTMIN+1 waybar
        }
        trap callback EXIT

        ${lib.getExe pkgs.timewarrior} "$@"
        exit "$?"
      '')
      # typst (markup-based typesetting system)
      unstable.typst

      # lidl-to-grocy (custom program to import lidl receipts into grocy)
      lidl-to-grocy
    ];
    modules.services.restic.paths = [ "${config.my.homeDirectory}/.timewarrior" ];

    hm.programs.zsh.shellAliases."dig" = "${pkgs.dogdns}/bin/dog";

    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    hm.programs.git.ignores = [
      ".envrc"
      ".direnv"
    ];

    # Locale
    # This keeps the system language as US English, but uses
    # European standards for everything else, namely dates,
    # currency, number formatting and paper sizes.
    # https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
    i18n = {
      defaultLocale = "en_IE.UTF-8";
      extraLocaleSettings = {
        LANGUAGE = "en_US";
      };
    };

    # Android Debug Bridge
    usr.extraGroups = [ "adbusers" ];
    programs.adb.enable = true;

    # needed for GSSAPIAuthentication options for ssh
    programs.ssh.package = pkgs.openssh_gssapi;

    # ssh client config
    hm.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = { };
        "* !apollo !bacchus".setEnv = {
          TERM = "xterm-256color";
        };

        apollo = {
          hostname = "apollo.diogotc.com";
          user = "dtc";
        };
        bacchus = {
          hostname = "bacchus.diogotc.com";
          user = "dtc";
        };

        athena = {
          hostname = "world.athena.diogotc.com";
          user = "dtc";
        };
        bro = {
          hostname = "world.bro.diogotc.com";
          user = "dtc";
        };
        feb = {
          hostname = "feb.diogotc.com";
          user = "dtc";
        };
        gammal = {
          hostname = "192.168.100.51";
          user = "dtc";
        };
        hades = {
          hostname = "hades.pedropirescoaching.com";
          user = "dtc";
        };
        hera = {
          hostname = "hera.diogotc.com";
          user = "dtc";
        };
        phobos = {
          hostname = "world.phobos.diogotc.com";
          user = "dtc";
        };
        poseidon = {
          hostname = "mail.lpespaco.pt";
          user = "dtc";
        };
        zeus = {
          hostname = "world.zeus.diogotc.com";
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

      extraConfig = ''
        VerifyHostKeyDNS yes
      '';
    };

    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${lib.getExe pkgs.dix} /run/current-system "$systemConfig"
      '';
    };
  };
}
