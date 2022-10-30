# overlays/discord.nix
#
# Author: João Borges <RageKnify@gmail.com>
# URL:    https://github.com/RageKnify/Config
#
# Need to use nss_latest like Firefox for hyperlinks to work

{ ... }: final: prev: rec {
  discord-nss_latest = prev.discord.override {
    nss = final.nss_latest;
  };
}
