# overlays/dmenu/default.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Apply patches to dmenu
{...}: final: prev: rec {
  dmenu = prev.dmenu.overrideAttrs (oldAttrs: rec {
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
