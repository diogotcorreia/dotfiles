# overlays/dwm/default.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Apply patches to DWM

{ inputs, ... }:
final: prev: rec {
  dwm = prev.dwm.overrideAttrs
    (oldAttrs: rec { patches = [ ./0001-keybinds.diff ]; });
}
