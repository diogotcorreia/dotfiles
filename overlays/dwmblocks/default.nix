# overlays/dwmblocks/default.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Apply patches to DWMBlocks

{ inputs, ... }:
final: prev: rec {
  dwmblocks = prev.dwmblocks.overrideAttrs (oldAttrs: rec {
    src = prev.fetchFromGitHub {
      owner = "LukeSmithxyz";
      repo = "dwmblocks";
      rev = "5a6fa8d550c11552480f10e660073ca294d446b1";
      sha256 = "00lxfxsrvhm60zzqlcwdv7xkqzya69mgpi2mr3ivzbc8s9h8nwqx";
    };
    patches = [
      (prev.fetchpatch {
        url =
          "https://github.com/torrinfail/dwmblocks/commit/4d92b6ca6caae215a79f00d88404c018b9eac15f.patch";
        sha256 = "sha256-Rahx1EU9ijsKuqjdcuODDLWhsAq4X23j1kwstGXJrVQ=";
      })
      ./0001-cleanup.diff
      ./0002-max-length.diff
      ./0003-config.diff
    ];
  });
}
