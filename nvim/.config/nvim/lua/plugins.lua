-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Close brackets automatically
  use 'rstacruz/vim-closer'
  use 'tpope/vim-endwise'

  -- Custom statusbar
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  } 

  -- Fancy colors
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

end)
