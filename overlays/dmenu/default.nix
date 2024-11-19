# Apply patches to dmenu
{...}: final: prev: {
  dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-5.3.diff";
        sha256 = "sha256-uPuuwgdH2v37eaefnbQ93ZTMvUBcl3LAjysfOEPD1Y8=";
      })
      # Based on https://tools.suckless.org/dmenu/patches/bar_height/
      ./0001-dmenu-bar-height.diff
    ];

    # needed by fuzzymatch patch
    NIX_LDFLAGS = "-lm";
  });
}
