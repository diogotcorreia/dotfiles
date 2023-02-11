# overlays/dwm/default.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Apply patches to DWM

{ inputs, ... }:
final: prev: rec {
  dwm = prev.dwm.overrideAttrs (oldAttrs: rec {
    patches = [
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/status2d/dwm-status2d-6.3.diff";
        sha256 = "sha256-thwe2p2uw09a7Se3Petik1ILkUSsblkZDb5BbfEQKSw=";
      })
      (prev.fetchpatch {
        url =
          "https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-status2d-20210405-60bb3df.diff";
        sha256 = "sha256-d7kkM6o+K9KbpEyTkdyJZRBHhN4Lb7cLX3JFb4q+zs4=";
      })
      (prev.fetchpatch {
        url =
          "https://dwm.suckless.org/patches/focusmonmouse/dwm-focusmonmouse-6.2.diff";
        sha256 = "sha256-BsbcljMjsQne4gLbLE1o1RbQD43DwPcGDF9N3eu7AF8=";
      })
      ./0001-keybinds.diff
      ./0002-fonts.diff
      # dwm-statuspadding patch was not compatible with status2d
      # https://dwm.suckless.org/patches/statuspadding/
      # This Reddit thread provides guidance on how to create it a custom patch for it:
      # https://www.reddit.com/r/suckless/comments/v3ktt6/comment/ib4kz2s/
      ./0003-dwm-statuspadding.diff
      # Remove background color from the middle section, where the window
      # title is, when there is a focused window in that monitor.
      ./0004-remove-bgcolor-window-title.diff

      ./0100-theme-colors.diff
    ];
  });
}
