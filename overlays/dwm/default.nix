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
        sha256 = "1m88qcbbp7q66yz2v98aal4fc6vs91mrpvp4psdlnxw074hjcidg";
      })
      (prev.fetchpatch {
        url =
          "https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-status2d-20210405-60bb3df.diff";
        sha256 = "1sshhm0y1y4h6j3fnnkrkz6g3j6z0iljwgahdq4lhxsp5f9mf858";
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
