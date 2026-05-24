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
      # Android Debug Bridge (adb)
      android-tools
      # doggo DNS CLI client (dig alternative)
      doggo
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

    hm.programs.fish.shellAliases."dig" = "${lib.getExe pkgs.doggo}";

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

    # needed for GSSAPIAuthentication options for ssh
    programs.ssh.package = pkgs.openssh_gssapi;

    # ssh client config
    hm.programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = { };
        "* !apollo !bacchus".SetEnv = {
          TERM = "xterm-256color";
        };

        apollo = {
          HostName = "apollo.diogotc.com";
          User = "dtc";
        };
        bacchus = {
          HostName = "bacchus.diogotc.com";
          User = "dtc";
        };

        athena = {
          HostName = "world.athena.diogotc.com";
          User = "dtc";
        };
        bro = {
          HostName = "world.bro.diogotc.com";
          User = "dtc";
        };
        feb = {
          HostName = "feb.diogotc.com";
          User = "dtc";
        };
        gammal = {
          HostName = "192.168.100.51";
          User = "dtc";
        };
        hades = {
          HostName = "hades.pedropirescoaching.com";
          User = "dtc";
        };
        hera = {
          HostName = "hera.diogotc.com";
          User = "dtc";
        };
        phobos = {
          HostName = "world.phobos.diogotc.com";
          User = "dtc";
        };
        poseidon = {
          HostName = "mail.lpespaco.pt";
          User = "dtc";
        };
        zeus = {
          HostName = "world.zeus.diogotc.com";
          User = "dtc";
        };

        sigma = {
          # use a specific server instead of load balancer for kerberos to work
          HostName = "sigma02.tecnico.ulisboa.pt";
          User = "ist199211";

          GSSAPIAuthentication = "yes";
          GSSAPIDelegateCredentials = "yes";
        };
        hs = {
          HostName = "server.hackerschool.io";
          User = "dtc";
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
