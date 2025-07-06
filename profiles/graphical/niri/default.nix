# Niri window manager (wayland)
{
  config,
  lib,
  pkgs,
  profiles,
  user,
  ...
}: let
  inherit (lib) flatten isAttrs isList mapAttrsToList removeAttrs;

  format = pkgs.my.kdl {};
  inherit (format.lib) node;

  # Recursively convert attrset to KDL node, using _type, _args, and _props attributes
  # for settings the type, arguments and properties of the node, respectively.
  toNode = name: value: let
    type = value._type or null;
    arguments = value._args or [];
    properties = value._props or {};
    children = flatten (mapAttrsToList toNode (
      removeAttrs value ["_type" "_args" "_props"]
    ));
  in
    if isAttrs value
    then (node name type arguments properties children)
    else if isList value
    then map (toNode name) value
    else (node name null [value] {} []);

  mkProps = props: {_props = props;};

  generate = settings: format.generate "config.kdl" (flatten (mapAttrsToList toNode settings));

  monitorsHorizontally = config.my.graphical.monitorDirection == "horizontally";
  monitorPrevious =
    if monitorsHorizontally
    then "left"
    else "up";
  monitorNext =
    if monitorsHorizontally
    then "right"
    else "down";
in {
  imports = with profiles; [
    graphical.fonts
    graphical.fuzzel
    graphical.swaylock
    graphical.waybar
  ];

  hm.home.packages = with pkgs; [
    niri
    xwayland-satellite
  ];

  hm.programs.zsh.initContent = ''
    # Start graphical server on user's current tty if not already running.
    [ "$(tty)" = "/dev/tty1" ] && ! pidof -s niri >/dev/null 2>&1 && exec niri-session &> /dev/null
  '';

  # Unlock keyring on login
  # System-wide option is needed for unlocking with PAM, while the HM option deals with starting the daemon
  # with the graphical session.
  services.gnome.gnome-keyring.enable = true;
  hm.services.gnome-keyring.enable = true;
  # TODO: probably remove in NixOS 25.11 due to the move to gcr-ssh-agent
  hm.systemd.user.services.gnome-keyring.Service.ExecStartPost = "-${config.systemd.package}/bin/systemctl --user set-environment SSH_AUTH_SOCK=%t/keyring/ssh";

  # The HM module is broken: https://github.com/nix-community/home-manager/issues/6770
  xdg.portal = {
    enable = true;
    configPackages = with pkgs; [niri];
    xdgOpenUsePortal = true;
    # Extra portals recommended by upstream
    extraPortals = with pkgs; [
      gnome-keyring
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # Avoid typing the username on TTY and only prompt for the password
  # https://wiki.archlinux.org/title/Getty#Prompt_only_the_password_for_a_default_user_in_virtual_console_login
  services.getty.loginOptions = "-p -- ${user}";
  services.getty.extraArgs = ["--noclear" "--skip-login"];

  # The generator exposed by home-manager is semi-broken and can't represent
  # certain needed options for the config (e.g. input.touchpad.tap).
  # For the time being, write the config using a custom KDL generator.
  # https://github.com/nix-community/home-manager/pull/3399#issuecomment-1936575067
  hm.xdg.configFile."niri/config.kdl".source = generate {
    input = {
      keyboard = {
        xkb = {
          layout = "us";
          variant = "altgr-intl";
        };
      };
      touchpad = {
        tap = {};
        natural-scroll = {};
      };
      warp-mouse-to-focus = {};
      focus-follows-mouse = {};
    };

    # Disable client-side decorations
    prefer-no-csd = {};

    layout = {
      gaps = 8;

      preset-column-widths = {
        proportion = [
          0.33333
          0.5
          0.66667
        ];
      };

      default-column-width = {
        proportion = 0.5;
      };

      focus-ring = {
        width = 4;

        # TODO: use theme colors
        active-color = "#7fc8ff";
        inactive-color = "#505050";
      };

      # Disable border since we're using focus ring instead
      border = {
        off = {};
      };
    };

    output = map (monitor:
      {
        _args = [monitor.name];
      }
      // (lib.optionalAttrs (monitor.position != null) {
        position = mkProps {inherit (monitor.position) x y;};
      })
      // (lib.optionalAttrs monitor.primary {
        focus-at-startup = {};
      }))
    config.my.graphical.monitors;

    # Disable saving screenshots to disk
    screenshot-path = null;

    binds = {
      # Show available hotkeys (equals to Mod + ?)
      "Mod+Shift+Slash" = {show-hotkey-overlay = {};};

      # Spawn programs
      "Mod+Return" = {spawn = "alacritty";};
      "Mod+E" = {spawn = "fuzzel";};
      "Mod+O" = {spawn = "swaylock";};

      # Window actions
      "Mod+Q" = {close-window = {};};
      "Mod+R" = {switch-preset-column-width = {};};
      "Mod+Shift+R" = {reset-window-height = {};};
      "Mod+F" = {maximize-column = {};};
      "Mod+Shift+F" = {fullscreen-window = {};};
      "Mod+C" = {center-column = {};};

      # Monitor actions
      "Mod+Comma" = {"focus-monitor-${monitorPrevious}" = {};};
      "Mod+Shift+Comma" = {"move-window-to-monitor-${monitorPrevious}" = {};};
      "Mod+Period" = {"focus-monitor-${monitorNext}" = {};};
      "Mod+Shift+Period" = {"move-window-to-monitor-${monitorNext}" = {};};

      # Quit niri
      "Mod+Ctrl+Q" = {quit = {};};
    };

    environment = {
      DISPLAY = ":0";
      # Make Electron apps use Wayland by default
      NIXOS_OZONE_WL = "1";
    };
  };
}
