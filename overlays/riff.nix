# overlays/riff.nix
#
# Author: João Borges <RageKnify@gmail.com>
# URL:    https://github.com/RageKnify/Config
#
# Have access to riff

{ inputs, ... }: final: prev: rec {
  riff = inputs.riff.defaultPackage.x86_64-linux;
}
