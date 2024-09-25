# Set of configurations that might be useful when doing presentations
{
  lib,
  pkgs,
  ...
}: let
  mkObsSceneAction = scene: ''{.v = (const char*[]){"${lib.getExe pkgs.obs-cmd}", "scene", "switch", "${scene}", NULL}}'';
  mkKeybindConfig = {
    modifier ? "0",
    key,
    action ? "spawn",
    args,
  }: ''{${modifier},${key},${action},${args}}'';

  keybinds = [
    {
      key = "XK_KP_End"; # KP_1
      args = mkObsSceneAction "Slides";
    }
    {
      key = "XK_KP_Down"; # KP_2
      args = mkObsSceneAction "Terminal";
    }
    {
      key = "XK_KP_Next"; # KP_3
      args = mkObsSceneAction "Terminal + VM 1";
    }
    {
      key = "XK_KP_Left"; # KP_4
      args = mkObsSceneAction "Browser";
    }
    {
      key = "XK_KP_Begin"; # KP_5
      args = mkObsSceneAction "Game";
    }
  ];
in {
  # Add extra keybinds to DWM
  services.xserver.windowManager.dwm.package = pkgs.dwm.overrideAttrs (oldAttrs: {
    patches =
      oldAttrs.patches
      ++ [
        (pkgs.substituteAll {
          src = ./extra-dwm-keybinds.patch;
          env = {
            extraDwmKeybinds = lib.concatStringsSep "," (map mkKeybindConfig keybinds);
          };
        })
      ];
  });

  # Set light mode on various programs (better visibility on projectors)
  hm.programs.neovim.extraConfig = ''
    colorscheme base16-one-light
    set nofoldenable
  '';
}
