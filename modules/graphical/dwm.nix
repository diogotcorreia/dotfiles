# DWM window manager and graphical environment configuration
{
  pkgs,
  config,
  lib,
  configDir,
  user,
  ...
}: let
  inherit (lib) mkEnableOption mkIf escapeShellArg;
  cfg = config.modules.graphical;

  # Cursor configuration
  cursor = rec {
    package = pkgs.gnome.adwaita-icon-theme;
    name = "Adwaita";
    size = 16;
    defaultCursor = "left_ptr";

    cursorPath = "${package}/share/icons/${escapeShellArg name}/cursors/${
      escapeShellArg defaultCursor
    }";
  };
in {
  options.modules.graphical.enable =
    mkEnableOption "DWM and graphical environment";

  config = mkIf cfg.enable {
    programs.slock.enable = true;
    programs.seahorse.enable = true;
    environment.systemPackages = with pkgs; [
      dmenu
      (pkgs.writeShellScriptBin "pulsemixer" ''
        ${pkgs.pulsemixer}/bin/pulsemixer "$@"
        pkill -RTMIN+10 dwmblocks
      '')
    ];

    fonts.packages = with pkgs; [
      fira-code
      nerdfonts
      noto-fonts
      noto-fonts-extra
      noto-fonts-emoji
      noto-fonts-cjk-sans
    ];

    # Avoid typing the username on TTY and only prompt for the password
    # https://wiki.archlinux.org/title/Getty#Prompt_only_the_password_for_a_default_user_in_virtual_console_login
    services.getty.loginOptions = "-p -- ${user}";
    services.getty.extraArgs = ["--noclear" "--skip-login"];

    # https://unix.stackexchange.com/questions/344402/how-to-unlock-gnome-keyring-automatically-in-nixos
    services.gnome.gnome-keyring.enable = true;
    # Service is "login" because login is done through the TTY
    security.pam.services.login.enableGnomeKeyring = true;

    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };
      autorun = true;
      displayManager.startx.enable = true;
      windowManager = {dwm.enable = true;};
    };

    services.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        naturalScrolling = true;
        middleEmulation = false;
      };
    };

    hm.home.pointerCursor = {
      inherit (cursor) package name size;
      x11 = {
        # WARNING: DWM overrides this for some reason I cannot figure out
        # A hacky workaround is provided in hm.xsession.initExtra
        inherit (cursor) defaultCursor;
        enable = true;
      };
      gtk.enable = config.modules.graphical.gtk.enable;
    };

    hm.home.file.".xinitrc".text = ''
      #! ${pkgs.bash}
      $HOME/.xsession
    '';

    hm.xsession = {
      enable = true;
      windowManager.command = "while type dwm >/dev/null; do dwm && continue || break; done";

      profileExtra = ''
        # https://nixos.wiki/wiki/Using_X_without_a_Display_Manager
        if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
          eval $(dbus-launch --exit-with-session --sh-syntax)
        fi
        systemctl --user import-environment DISPLAY XAUTHORITY

        if command -v dbus-update-activation-environment >/dev/null 2>&1; then
          dbus-update-activation-environment DISPLAY XAUTHORITY
        fi

        # Start GNOME Keyring to unlock on login
        eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh);
        export SSH_AUTH_SOCK

        # Fix Java applications not rendering correctly on DWM
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';

      initExtra = ''
        # Hack to fix DWM overriding the cursor theme.
        # Does the same as hm.home.pointerCursor.x11.defaultCursor, but
        # after a sleep, in order to execute after DWM starting.
        (${pkgs.coreutils}/bin/sleep 0.2 && ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cursor.cursorPath} ${
          toString cursor.size
        }) &
      '';
    };

    hm.programs.zsh.initExtra = ''
      # Start graphical server on user's current tty if not already running.
      [ "$(tty)" = "/dev/tty1" ] && ! pidof -s Xorg >/dev/null 2>&1 && exec startx "$XINITRC" &> /dev/null
    '';

    programs.light.enable = true;
    usr.extraGroups = ["video"];

    hm.services.picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      settings = {unredir-if-possible = false;};
    };

    hm.services.flameshot = {
      enable = true;
      settings = {
        General = {
          disabledTrayIcon = true;
          savePath = "/tmp";
          savePathFixed = false;
          saveAsFileExtension = ".png";
          uiColor = "${lib.my.colors.lightblue}";
          startupLaunch = false;
          antialiasingPinZoom = true;
          uploadWithoutConfirmation = false;
          predefinedColorPaletteLarge = true;
        };
      };
    };

    # Clipboard manager
    hm.services.clipmenu.enable = true;

    # Notification daemon
    hm.services.dunst = {
      enable = true;
      configFile = configDir + "/dunstrc";
    };
    # Utility to quickly toggle notification mute
    hm.home.packages = [
      (pkgs.writeScriptBin "toggle-dunst-notifications" ''
        #! /usr/bin/env sh

        # Wrapper to toggle dunst 'set-pause' and send signal to dwmblocks to reload widget

        ${pkgs.dunst}/bin/dunstctl set-paused toggle && pkill -RTMIN+19 dwmblocks
      '')
    ];

    # Enable redshift when X starts
    hm.services.redshift = {
      enable = true;
      provider = "manual";
      latitude = 38.7436214;
      longitude = -9.1952226;
    };
  };
}
