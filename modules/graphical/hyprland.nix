# modules/graphical/hyprland.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Hyprland window manager and graphical environment configuration

{ pkgs, config, lib, configDir, user, colors, ... }:
let
  inherit (lib) mkEnableOption mkIf escapeShellArg;
  cfg = config.modules.graphical;

  hyprlandPackage = pkgs.unstable.hyprland;
  hyprlandPortalPackage = pkgs.unstable.xdg-desktop-portal-hyprland.override {
    hyprland = config.home-manager.users.${user}.wayland.windowManager.hyprland.finalPackage;
  };
in
{
  # options.modules.graphical.enable =
  # mkEnableOption "Hyprland and graphical environment";

  config = mkIf cfg.enable {
    # TODO fonts

    hm.wayland.windowManager.hyprland = {
      enable = true;
      package = hyprlandPackage;

      systemd.enable = true;

      settings = {
        "$mod" = "SUPER";

        # https://wiki.hyprland.org/Configuring/Monitors/
        monitor = ",preferred,auto,1";

        # https://wiki.hyprland.org/Configuring/Variables/
        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";

          scroll_method = "2fg"; # 2 fingers
          natural_scroll = false;

          touchpad = {
            disable_while_typing = false;
            natural_scroll = true;

            # TODO seems interesting, experimenting for a while
            drag_lock = true;
          };
        };

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          # TODO do we really need the quotes?
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";

          layout = "dwindle";
        };

        misc = {
          disable_hyprland_logo = true;
        };

        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };

          drop_shadow = true;
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1aee)";
        };

        # https://wiki.hyprland.org/Configuring/Animations/
        animations = {
          enabled = true;

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        # https://wiki.hyprland.org/Configuring/Dwindle-Layout/
        dwindle = {
          pseudotile = "yes";
          preserve_split = "yes";
        };

        # https://wiki.hyprland.org/Configuring/Master-Layout/
        master = {
          new_is_master = true;
        };

        # https://wiki.hyprland.org/Configuring/Variables/
        gestures = {
          # TODO consider turning this on
          workspace_swipe = "off";
        };

        # https://wiki.hyprland.org/Configuring/Binds/
        bind = [
          "$mod, return, exec, ${pkgs.alacritty}/bin/alacritty"
          "$mod, Q, killactive,"
          "$mod, M, exit,"
          "$mod, E, exec, dolphin"
          "$mod, V, togglefloating,"
          "$mod, R, exec, wofi --show drun"
          "$mod, P, pseudo," # dwindle
          "$mod, J, togglesplit," # dwindle

          # Move focus with mainMod + arrow keys
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Scroll through existing workspaces with mainMod + scroll
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          ", print, exec, ${pkgs.flameshot}/bin/flameshot gui"
          "SHIFT, print, exec, ${pkgs.flameshot}/bin/flameshot full --path \"$XDG_PICTURES_DIR\""
        ];

        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];
      };
    };

    # Add extra portals (file picker, etc)
    xdg.portal = {
      enable = true;
      extraPortals = [ hyprlandPortalPackage
      # pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [ hyprlandPackage ];
    };

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
