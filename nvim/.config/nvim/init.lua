local o = vim.o -- global options
local wo = vim.wo -- window-local options
local bo = vim.bo -- buffer-local options

-- disable Vim startup message
o.shortmess = o.shortmess .. 'I'

-- show (relative) line numbers
wo.number = true
wo.relativenumber = true

-- enable hidden buffers
o.hidden = true

-- show invisible whitespace characters
o.list = true
o.listchars = "tab:>-,trail:~,extends:>,precedes:<"

-- use smart case on searches: if it's all lowercase, search is case insensitive;
-- if there's a upper case character, search is case sensitive
o.ignorecase = true
o.smartcase = true

-- disable audible bell for sanity reasons
o.errorbells = false
o.visualbell = true

-- enable mouse support for convenience
o.mouse = o.mouse .. 'a'

-- keep a line offset around cursor
o.scrolloff = 12

-- use spaces instead of tab
bo.expandtab = true

-- use sane clipboard shortcuts
vim.api.nvim_set_keymap('', '<Leader>p', '"+p', { noremap = true})
vim.api.nvim_set_keymap('', '<Leader>P', '"+P', { noremap = true})
vim.api.nvim_set_keymap('', '<Leader>y', '"+y', { noremap = true})
vim.api.nvim_set_keymap('n', '<Leader>Y', '"+y$', { noremap = true})

require('plugins')
require('statusbar')
