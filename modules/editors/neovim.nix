# modules/editors/neovim.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# neovim home configuration. (Based on RageKnify's)
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf lists strings;
  cfg = config.modules.editors.neovim;
  personal = config.modules.personal.enable;
  git = config.modules.shell.git.enable;
  commonGrammars = with pkgs.unstable.vimPlugins.nvim-treesitter.builtGrammars; [
    bash
    comment
    html
    markdown
    nix
    python
  ];
  personalGrammars = with pkgs.unstable.vimPlugins.nvim-treesitter.builtGrammars;
    lists.optionals personal [
      c
      cpp
      java
      javascript
      latex
      lua
      rust
      toml
      typescript
      pkgs.unstable.tree-sitter-grammars.tree-sitter-typst
      vim
      yaml
    ];
  commonPlugins = with pkgs.unstable.vimPlugins; [
    nvim-web-devicons
    {
      plugin = lualine-nvim;
      type = "lua";
      config = ''
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

        vim.o.laststatus=2
        vim.o.showtabline=2
        vim.o.showmode=false
        require'lualine'.setup {
          options = {
            theme = 'auto',
            section_separators = {left='', right=''},
            component_separators = {left='', right=''},
            icons_enabled = true
          },
          sections = {
            lualine_b = { ${strings.optionalString git "'diff'"} },
            lualine_c = {
              {'diagnostics', {
                sources = {nvim_diagnostic},
                symbols = {error = ':', warn =':', info = ':', hint = ':'}}},
              {'filename', file_status = true, path = 1}
            },
            lualine_x = { getWordCount, 'encoding', {'filetype', colored = false} },
          },
          inactive_sections = {
            lualine_c = {
              {'filename', file_status = true, path = 1}
            },
            lualine_x = { getWordCount, 'encoding', {'filetype', colored = false} },
          },
          tabline = {
            lualine_a = { 'hostname' },
            lualine_b = { ${strings.optionalString git "'branch'"} },
            lualine_z = { {'tabs', tabs_color = { inactive = "TermCursor", active = "ColorColumn" } } }
          },
          extensions = { fzf${strings.optionalString git ", fugitive "} },
          }
          if _G.Tabline_timer == nil then
            _G.Tabline_timer = vim.loop.new_timer()
          else
            _G.Tabline_timer:stop()
          end
          _G.Tabline_timer:start(0,             -- never timeout
                                 1000,          -- repeat every 1000 ms
                                 vim.schedule_wrap(function() -- updater function
                                                      vim.api.nvim_command('redrawtabline')
                                                   end))
      '';
    }

    {
      plugin = delimitMate;
      config = ''
        let delimitMate_expand_cr=2
        let delimitMate_expand_space=1
      '';
    }

    {
      plugin = vim-illuminate;
      config = ''
        let g:Illuminate_delay = 100
        hi def link LspReferenceText CursorLine
        hi def link LspReferenceRead CursorLine
        hi def link LspReferenceWrite CursorLine
      '';
    }

    {
      plugin =
        nvim-treesitter.withPlugins
        (plugins: commonGrammars ++ personalGrammars);
      type = "lua";
      config = ''
        -- enable highlighting
        require'nvim-treesitter.configs'.setup { highlight = { enable = true } }

        local function define_fdm()
          if (require "nvim-treesitter.parsers".has_parser()) then
            -- with treesitter parser
            vim.wo.foldexpr="nvim_treesitter#foldexpr()"
            vim.wo.foldmethod="expr"
          else
            -- without treesitter parser
            vim.wo.foldmethod="syntax"
          end
        end
        vim.api.nvim_create_autocmd({ "FileType" }, { callback = define_fdm })
      '';
    }

    vim-signature

    {
      plugin = fzf-lua;
      type = "lua";
      config = ''
        local fzf_lua = require('fzf-lua')
        fzf_lua.setup{
          fzf_opts = {
            ['--layout'] = 'reverse',
          },
          winopts = {
            height = 0.75,
            width = 0.75,
          },
        }
        local set = vim.keymap.set
        local files = function()
          vim.fn.system('git rev-parse --is-inside-work-tree')
          if vim.v.shell_error == 0 then
            fzf_lua.git_files()
          else
            fzf_lua.files()
          end
        end
        -- fuzzy find files in the working directory (where you launched Vim from)
        set('n', '<leader>f', files)
        -- fuzzy find lines in the current file
        set('n', '<leader>/', fzf_lua.blines)
        -- fuzzy find an open buffer
        set('n', '<leader>b', fzf_lua.buffers)
        -- fuzzy find text in the working directory
        set('n', '<leader>rg', fzf_lua.grep_project)
        -- fuzzy find Vim commands (like Ctrl-Shift-P in Sublime/Atom/VSC)
        set('n', '<leader>c', fzf_lua.commands)
      '';
    }

    {
      plugin = nerdcommenter;
      type = "lua";
      config = ''
        vim.g.NERDCreateDefaultMappings = 0
        vim.g.NERDSpaceDelims = 1

        vim.keymap.set('n', '<leader>cc', '<Plug>NERDCommenterToggle')
        vim.keymap.set('x', '<leader>cc', '<Plug>NERDCommenterToggle')
      '';
    }

    {
      plugin = nvim-base16;
      config = ''
        " colorscheme settings
        set background=dark
        colorscheme base16-nord
      '';
    }

    plenary-nvim

    {
      plugin = pkgs.nvim-osc52;
      type = "lua";
      config = ''
        local function copy(lines, _)
          require('osc52').copy(table.concat(lines, '\n'))
        end

        local function paste()
          return {vim.fn.split(vim.fn.getreg(""), '\n'), vim.fn.getregtype("")}
        end

        vim.g.clipboard = {
          name = 'osc52',
          copy = {['+'] = copy, ['*'] = copy},
          paste = {['+'] = paste, ['*'] = paste},
        }

        -- Now the '+' register will copy to system clipboard using OSC52
        vim.keymap.set(''', '<leader>y', '"+y')
        vim.keymap.set('n', '<leader>Y', '"+y$')
      '';
    }

    {
      plugin = nvim-colorizer-lua;
      type = "lua";
      config = ''
        require 'colorizer'.setup ({ user_default_options = { names = false; }})
      '';
    }
  ];
  personalPlugins = with pkgs.unstable.vimPlugins;
    lists.optionals personal [
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          -- common lsp setup
          local lsp_config = require'lspconfig'
          local lsp_setup = require'generic_lsp'
          -- Rust lsp setup
          local rt = require("rust-tools")
          local capabilities = lsp_setup.capabilities
          local on_attach = lsp_setup.on_attach
          rt.setup({
            server = {
              capabilities = capabilities,
              on_attach = function(_, bufnr)
                -- Hover actions
                on_attach(_, bufnr)
                vim.keymap.set('n', 'K', rt.hover_actions.hover_actions, {silent=true})
              end,
              settings = {
                ["rust-analyzer"] = {
                  checkOnSave = {
                    command = "clippy",
                  },
                },
              },
            },
          })
          -- other lsp setup
          local with_config = function(config)
            config['capabilities'] = capabilities
            config['on_attach'] = on_attach
            return config
          end
          lsp_config.tsserver.setup(lsp_setup)
          lsp_config.ccls.setup(lsp_setup)
          lsp_config.nil_ls.setup(with_config({
            settings = {
              ['nil'] = {
                formatting = {
                  command = { "${lib.getExe pkgs.alejandra}" }
                },
              },
            },
          }))
          lsp_config.html.setup({ cmd = { "html-languageserver", "--stdio" }, unpack(lsp_setup) })
          -- don't let the LSP generate the PDF, otherwise it will collide with typst watch
          lsp_config.typst_lsp.setup({ settings = { exportPdf = "never" }, unpack(lsp_setup) })
        '';
      }
      rust-tools-nvim

      luasnip
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          -- Setup nvim-cmp.
          local cmp = require'cmp'
          cmp.setup({
            snippet = {
              -- REQUIRED - you must specify a snippet engine
              expand = function(args)
                require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
              end,
            },
            window = {
              -- completion = cmp.config.window.bordered(),
              -- documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
              { name = 'treesitter' },
              { name = 'spell' },
              { name = 'path' },
              { name = 'buffer' },
            })
          })
          -- autocomplete commits, Issue/PR numbers, mentions
          cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({
              { name = 'git' },
              { name = 'spell' },
              { name = 'buffer' },
            })
          })
          -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline('/', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
              { name = 'buffer' },
            }
          })
          -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
          cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
              { name = 'path' },
              { name = 'cmdline' },
            })
          })
        '';
      }
      cmp_luasnip
      cmp-treesitter
      cmp-nvim-lsp
      cmp-spell
      cmp-path
      cmp-git

      {
        plugin = guess-indent-nvim;
        type = "lua";
        config = ''
          require('guess-indent').setup {}
        '';
      }

      {
        plugin = typst-vim;
        type = "lua";
        config = ''
          vim.keymap.set('n', '<leader>tw', function() vim.fn['typst#TypstWatch']() end, { silent = true })
        '';
      }
    ];
  gitPlugins = with pkgs.unstable.vimPlugins;
    lists.optionals git [
      vim-fugitive
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require('gitsigns').setup{
            signs = {
              add = {  text = '+' },
            },
            on_attach = function(bufnr)
              local gs = package.loaded.gitsigns
              local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
              end
              map('n', '<leader>gb', gs.toggle_current_line_blame)
            end,
          }
        '';
      }
    ];
  personalPackages = with pkgs;
    lists.optionals personal [
      python311Packages.jedi-language-server # Python LSP
      ccls # C/C++ LSP
      nodePackages.typescript-language-server # JS/TS LSP
      nodePackages.vscode-html-languageserver-bin # HTML LSP
      nil # Nix LSP
      unstable.typst-lsp # Typst LSP
    ];
in {
  options.modules.editors.neovim.enable = mkEnableOption "neovim";

  # Home manager module
  config.hm = mkIf cfg.enable {
    programs.neovim = {
      package = pkgs.unstable.neovim-unwrapped;
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraLuaConfig = ''
        -- change leader key to space bar
        vim.g.mapleader = " "

        -- use 2 space identation by default
        vim.api.nvim_create_user_command('Spaces',
          function(opts)
            local count = tonumber(opts.fargs[1])
            vim.opt.shiftwidth = count
            vim.opt.softtabstop = count
            vim.opt.tabstop = count
            vim.opt.expandtab = true
          end,
          { nargs = 1 })
        vim.api.nvim_create_user_command('Tabs',
          function(opts)
            local count = tonumber(opts.fargs[1])
            vim.opt.shiftwidth = count
            vim.opt.softtabstop = count
            vim.opt.tabstop = count
            vim.opt.expandtab = false
          end,
          { nargs = 1 })
        vim.cmd.Spaces(2)

        -- show invisible whitespace characters
        vim.opt.list = true
        vim.opt.listchars = { tab = '>-', trail = '~', extends = '>', precedes = '<' }

        -- delete trailing whitespace
        vim.api.nvim_create_autocmd('FileType', {
          pattern = { 'c', 'cpp', 'java', 'lua', 'nix', 'vim' },
          callback = function()
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = 0,
              callback = function()
                -- make sure cursor doesn't jump around
                local cursor_pos = vim.api.nvim_win_get_cursor(0)
                vim.cmd('%s/\\s\\+$//e')
                vim.api.nvim_win_set_cursor(0, cursor_pos)
              end,
            })
          end,
        })

        -- makes n=Next and N=Previous for find (? / /)
        -- https://vi.stackexchange.com/a/2366
        vim.keymap.set('n', 'n', "'Nn'[v:searchforward]", { expr = true })
        vim.keymap.set('n', 'N', "'nN'[v:searchforward]", { expr = true })

        -- easy bind to leave terminal mode
        vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

        -- keep undo history over different sessions
        vim.opt.undofile = true
        vim.opt.undodir = '/tmp//'

        -- restore last cursor position when opening buffer (file)
        vim.api.nvim_create_autocmd('BufReadPost', {
          pattern = '*',
          callback = function()
            vim.api.nvim_exec('silent! normal! g`"zv', false)
          end,
        })

        -- don't save cursor position when writing git commit messages
        vim.api.nvim_create_autocmd('BufReadPost', {
          pattern = 'COMMIT_EDITMSG',
          callback = function()
            vim.opt_local.viminfofile = "NONE"
          end,
        })

        -- use arrows to resize windows
        vim.keymap.set('n', '<Up>', function() vim.api.nvim_win_set_height(0, vim.api.nvim_win_get_height(0) + 2) end)
        vim.keymap.set('n', '<Down>', function() vim.api.nvim_win_set_height(0, vim.api.nvim_win_get_height(0) - 2) end)
        vim.keymap.set('n', '<Left>', function() vim.api.nvim_win_set_width(0, vim.api.nvim_win_get_width(0) + 2) end)
        vim.keymap.set('n', '<Right>', function() vim.api.nvim_win_set_width(0, vim.api.nvim_win_get_width(0) - 2) end)

        -- move to the split in the direction shown, or create a new split
        function WinMove(key)
          return function()
            local curwin = vim.api.nvim_get_current_win()
            vim.cmd('wincmd ' .. key)
            if curwin == vim.api.nvim_get_current_win() then
              -- we did not move; create new split
              if key == 'j' or key == 'k' then
                vim.cmd('wincmd s')
              else
                vim.cmd('wincmd v')
              end
              vim.cmd('wincmd ' .. key)
            end
          end
        end
        vim.keymap.set('n', '<C-h>', WinMove('h'), { silent = true })
        vim.keymap.set('n', '<C-j>', WinMove('j'), { silent = true })
        vim.keymap.set('n', '<C-k>', WinMove('k'), { silent = true })
        vim.keymap.set('n', '<C-l>', WinMove('l'), { silent = true })

        -- clear search highlight
        vim.keymap.set('n', '<leader><leader>', function() vim.cmd("nohlsearch") end, { silent = true })

        -- move lines up and down in visual mode
        vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
        vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

        -- overwrite selection with clipboard without losing clipboard
        vim.keymap.set("x", "<leader>p", '"_dP')

        -- delete without losing clipboard
        vim.keymap.set({"n", "v"}, "<leader>d", '"_d')

        -- quick-replace word under cursor
        vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
        vim.keymap.set("v", "<leader>s", [["hy:%s/\<<C-r>h\>/<C-r>h/gI<Left><Left><Left>]])

        -- don't include character under cursor in selection
        vim.opt.selection = 'exclusive'
        -- enable mouse functionality
        vim.opt.mouse = 'a'

        -- highlight yank'ed text
        vim.api.nvim_create_autocmd('TextYankPost', {
          callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 1000, on_visual = true })
          end,
        })

        -- do not wrap lines
        vim.opt.wrap = false
        vim.keymap.set('n', '<leader>w', function() vim.opt.wrap = not vim.opt.wrap:get() end)

        -- keep a line offset around cursor
        vim.opt.scrolloff = 12

        -- when splitting, split below and to the right
        vim.opt.splitbelow = true
        vim.opt.splitright = true

        -- show (relative) line numbers
        vim.opt.number = true
        vim.opt.relativenumber = true

        -- use smart case on searches: if it's all lowercase, search is case insensitive;
        -- if there's a upper case character, search is case sensitive
        vim.opt.ignorecase = true
        vim.opt.smartcase = true

        -- disable audible bell for sanity reasons
        vim.opt.belloff = 'all'

        -- enable spell checker
        vim.opt.spell = true
        vim.opt.spelllang = { 'en', 'pt' }

        -- avoid typing W instead of w to save
        -- there is no native lua API for abbreviations
        vim.cmd('cabbrev W w')
        -- FIXME: only available starting in neovim 0.10 (nightly right now)
        -- vim.keymap.set('ca', 'W', 'w')
      '';
      plugins = commonPlugins ++ personalPlugins ++ gitPlugins;
    };

    home.file."${config.my.configHome}/nvim/lua/generic_lsp.lua".text = ''
      local lsp = require'lspconfig'
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          'documentation',
          'detail',
          'additionalTextEdits',
        }
      }
      local on_attach = function(client, bufnr)
        local set = vim.keymap.set
        -- [[ other on_attach code ]]
        set('n', 'K', vim.lsp.buf.hover, {silent=true})
        -- illuminate stuff
        local illuminate = require"illuminate"
        set('n', '<leader>gn', illuminate.next_reference, {silent=true})
        set('n', '<leader>gp', function () illuminate.next_reference{reverse=true} end, {silent=true})
        require 'illuminate'.on_attach(client)
        set('n', '<leader>n', function () vim.diagnostic.goto_next { wrap = false } end, {silent = true})
        set('n', '<leader>p', function () vim.diagnostic.goto_prev { wrap = false } end, {silent = true})
        set('n', '<leader>d', vim.lsp.buf.definition, {silent = true})
        set('n', '<leader>gr', vim.lsp.buf.references, {silent = true})
        set('n', '<leader>rn', vim.lsp.buf.rename, {silent = true})
        set('n', '<leader>a', vim.lsp.buf.code_action, {silent = true})
        set('n', '<leader>tt', function () vim.lsp.buf.format({ async = false }) end, {})
        set('n', '<leader><cr>', vim.diagnostic.open_float, {silent = true})
        -- Use LSP omni-completion in LSP enabled files.
        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
      end
      return {capabilities = capabilities, on_attach = on_attach}
    '';

    home.packages = personalPackages;

    home.sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
    systemd.user.sessionVariables = {EDITOR = "nvim";};
  };
}
