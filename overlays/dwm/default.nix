# Apply patches to DWM
{...}: final: prev: {
  dwm = prev.dwm.overrideAttrs (oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/status2d/dwm-status2d-6.3.diff";
        sha256 = "sha256-thwe2p2uw09a7Se3Petik1ILkUSsblkZDb5BbfEQKSw=";
      })
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/focusmonmouse/dwm-focusmonmouse-6.2.diff";
        sha256 = "sha256-BsbcljMjsQne4gLbLE1o1RbQD43DwPcGDF9N3eu7AF8=";
      })
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-20191112-cb3f58a.diff";
        sha256 = "sha256-SMqYYKM2dq+6aD2R3EDEuiGIn5yIhiYhnJKtrHacXBc=";
      })
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/underlinetags/dwm-underlinetags-6.2.diff";
        sha256 = "sha256-TSg2UtsRGhE+eE67qiOsfUQscTKFh2VYPb/1Sx8TOCw=";
      })
      (prev.fetchpatch {
        url = "https://dwm.suckless.org/patches/removeborder/dwm-removeborder-20220626-d3f93c7.diff";
        sha256 = "sha256-0QUN+wfKyXxabXyKXIcpPcdnLkH4d0Oqx8pncjc+It4=";
      })
      ./0001-keybinds.diff
      ./0002-fonts.diff
      # dwm-statuscmd
      # adaption of https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-status2d-20210405-60bb3df.diff
      # to be compatible with dwm 6.5
      ./0003-dwm-statuscmd.diff
      # dwm-statuspadding patch was not compatible with status2d
      # https://dwm.suckless.org/patches/statuspadding/
      # This Reddit thread provides guidance on how to create it a custom patch for it:
      # https://www.reddit.com/r/suckless/comments/v3ktt6/comment/ib4kz2s/
      ./0004-dwm-statuspadding.diff
      # Remove background color from the middle section, where the window
      # title is, when there is a focused window in that monitor.
      ./0005-remove-bgcolor-window-title.diff
      # Show status bar on all monitors
      # Based on https://dwm.suckless.org/patches/statusallmons/
      ./0006-dwm-statusallmons.diff
      # Preserve window tags and monitor when restarting DWM (i.e. to apply new patches)
      # Based on https://github.com/FT-Labs/pdwm/blob/5944027dd95ad5343e64a4f61a2209278e2880fb/patches/dwm-6.3-patches/dwm-preserveonrestart-6.3.diff
      ./0007-preserveonrestart.diff
      # Colorize each tag individually on status bar
      # Based on https://github.com/fitrh/dwm/issues/1
      ./0008-colorful-tags.diff

      ./0100-theme-colors.diff
      ./0101-tag-names.diff
    ];
  });
}
