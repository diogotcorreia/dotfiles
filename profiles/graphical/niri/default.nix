# Niri window manager (wayland)
{
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    graphical.fonts
  ];

  hm.home.packages = with pkgs; [niri];

  hm.programs.zsh.initExtra = ''
    # Start graphical server on user's current tty if not already running.
    [ "$(tty)" = "/dev/tty1" ] && ! pidof -s niri >/dev/null 2>&1 && exec niri-session &> /dev/null
  '';

  # The generator exposed by home-manager is semi-broken and can't represent
  # certain needed options for the config (e.g. input.touchpad.tap).
  # For the time being, write the config manually using KDL.
  # https://github.com/nix-community/home-manager/pull/3399#issuecomment-1936575067
  hm.xdg.configFile."niri/config.kdl".text = ''
    input {
      keyboard {
        xkb {
          layout "us"
          variant "altgr-intl"
        }
      }
      touchpad {
        tap
        natural-scroll
      }

      warp-mouse-to-focus
    }

    // Disable client-side decorations
    prefer-no-csd

    layout {
      gaps 8

      default-column-width { proportion 0.5; }

      focus-ring {
        width 4

        // TODO: use theme colors
        active-color "#7fc8ff"
        inactive-color "#505050"
      }

      // Disable border since we're using focus ring instead
      border {
        off
      }
    }

    // Disable saving screenshots to disk
    screenshot-path null

    binds {
      // Show available hotkeys (equals to Mod + ?)
      Mod+Shift+Slash { show-hotkey-overlay; }

      // Spawn programs
      Mod+Return { spawn "alacritty"; }

      // Quit niri
      Mod+Ctrl+Q { quit; }
    }
  '';
}
