# overlays/nvim-osc52.nix
#
# Author: João Borges <RageKnify@gmail.com>
# URL:    https://github.com/RageKnify/Config
#
# Have access to nvim-osc52

{ inputs, ... }: final: prev: rec {
  nvim-osc52 = final.vimUtils.buildVimPlugin {
    name = "nvim-osc52";
    src = inputs.nvim-osc52;
  };
}
