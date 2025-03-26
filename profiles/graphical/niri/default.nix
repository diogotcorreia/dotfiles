# Niri window manager (wayland)
{
  lib,
  pkgs,
  profiles,
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
in {
  imports = with profiles; [
    graphical.fonts
  ];

  hm.home.packages = with pkgs; [
    niri
    xwayland-satellite
  ];

  hm.programs.zsh.initExtra = ''
    # Start graphical server on user's current tty if not already running.
    [ "$(tty)" = "/dev/tty1" ] && ! pidof -s niri >/dev/null 2>&1 && exec niri-session &> /dev/null
  '';

  # The generator exposed by home-manager is semi-broken and can't represent
  # certain needed options for the config (e.g. input.touchpad.tap).
  # For the time being, write the config manually using KDL.
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

    output = [
      {
        _args = ["HDMI-A-1"];
        position = mkProps {
          x = 0;
          y = 0;
        };
      }
      {
        _args = ["eDP-1"];
        position = mkProps {
          x = 0;
          y = 1200;
        };
      }
    ];

    # Disable saving screenshots to disk
    screenshot-path = null;

    binds = {
      # Show available hotkeys (equals to Mod + ?)
      "Mod+Shift+Slash" = {
        show-hotkey-overlay = {};
      };

      # Spawn programs
      "Mod+Return" = {
        spawn = "alacritty";
      };

      # Quit niri
      "Mod+Ctrl+Q" = {
        quit = {};
      };
    };

    environment = {
      DISPLAY = ":0";
      # Make Electron apps use Wayland by default
      NIXOS_OZONE_WL = "1";
    };
  };
}
