# overlays/cfdyndns.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Use cfdyndns from nixos-unstable

{ ... }:
final: prev: rec {
  cfdyndns = prev.unstable.cfdyndns;
}
