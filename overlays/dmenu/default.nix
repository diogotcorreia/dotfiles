# Apply patches to dmenu
{...}: final: prev: {
  dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
    patches = [
      (prev.fetchpatch {
        url = "https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-4.9.diff";
        sha256 = "sha256-zfmsKfN791z6pyv+gA6trdfKvNnCCULazVtk1sibDgA=";
      })
      # Based on https://tools.suckless.org/dmenu/patches/bar_height/
      ./0001-dmenu-bar-height.diff
    ];
  });
}
