-- Customize statusbar (with lualine.nvim)

local function getWordCount()
  local word_count = vim.fn.wordcount().visual_words
  if word_count == nul then
    word_count = vim.fn.wordcount().words
  end

  if word_count == 1 then
    return tostring(word_count) .. " word"
  end
  return tostring(word_count) .. " words"
end

require('lualine').setup {
  options = {
    icons_enabled = true,
    theme = 'nord',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {},
    always_divide_middle = true,
    globalstatus = false,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {getWordCount, 'encoding', 'fileformat', 'filetype', 'filesize'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}
