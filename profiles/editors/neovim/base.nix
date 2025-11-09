{
  config,
  inputs,
  lib,
  user,
  ...
}:
let
  git = config.modules.shell.git.enable;
  lib' = config.home-manager.users.${user}.lib.nixvim;
in
{
  home-manager.sharedModules = [
    inputs.nixvim.homeManagerModules.default
  ];

  hm.programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    colorschemes.base16 = {
      enable = true;
      colorscheme = "nord";
    };

    globals = {
      mapleader = " ";
      clipboard = "osc52";
    };

    opts = {
      # show invisible whitespace characters
      list = true;
      listchars = {
        tab = ">-";
        trail = "~";
        extends = ">";
        precedes = "<";
      };

      # keep undo history over different sessions
      undofile = true;
      undodir = "/tmp//";

      # don't include character under cursor in selection
      selection = "exclusive";
      # enable mouse functionality
      mouse = "a";

      # do not wrap lines by default (<leader>w to toggle)
      wrap = false;

      # keep a line offset around cursor
      scrolloff = 12;

      # when splitting, split below and to the right
      splitbelow = true;
      splitright = true;

      # show (relative) line numbers
      number = true;
      relativenumber = true;

      # use smart case on searches: if it's all lowercase, search is case insensitive;
      # if there's a upper case character, search is case sensitive
      ignorecase = true;
      smartcase = true;

      # expand sign column if needed
      signcolumn = "auto:9";

      # disable audible bell for sanity reasons
      belloff = "all";

      # enable spell checker
      spell = true;
      spelllang = [
        "en"
        "pt"
      ];
    };

    keymaps = [
      # copy to system clipboard register
      {
        key = "<leader>y";
        action = ''"+y'';
      }
      {
        key = "<leader>Y";
        action = ''"+y$'';
        mode = "n";
      }

      # makes n=Next and N=Previous for find (? / /)
      # https://vi.stackexchange.com/a/2366
      {
        key = "n";
        action = "'Nn'[v:searchforward]";
        mode = "n";
        options.expr = true;
      }
      {
        key = "N";
        action = "'nN'[v:searchforward]";
        mode = "n";
        options.expr = true;
      }

      # easy bind to leave terminal mode
      {
        key = "<Esc>";
        action = "<C-\\><C-n>";
        mode = "t";
      }

      # clear search highlight
      {
        key = "<leader><leader>";
        action = ":nohlsearch<CR>";
        mode = "n";
        options.silent = true;
      }

      # move lines up and down in visual mode
      {
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        mode = "v";
      }
      {
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        mode = "v";
      }

      # overwrite selection with clipboard without losing clipboard
      {
        key = "<leader>p";
        action = ''"_dP'';
        mode = "x";
      }

      # delete without losing clipboard
      {
        key = "<leader>d";
        action = ''"_d'';
        mode = [
          "n"
          "v"
        ];
      }

      # quick-replace word under cursor
      {
        key = "<leader>s";
        action = lib'.mkRaw "[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]";
        mode = "n";
      }
      {
        key = "<leader>s";
        action = lib'.mkRaw ''[["hy:%s/\<<C-r>h\>/<C-r>h/gI<Left><Left><Left>]]'';
        mode = "v";
      }

      # keep selection when changing indentation
      {
        key = "<";
        action = "<gv";
        mode = "v";
      }
      {
        key = ">";
        action = ">gv";
        mode = "v";
      }

      # repeat macro
      # https://vi.stackexchange.com/questions/11210/can-i-repeat-a-macro-with-the-dot-operator
      {
        key = "<leader>.";
        action = "@@";
        mode = "n";
      }

      # toggle wrapping
      {
        key = "<leader>w";
        action = lib'.mkRaw ''
          function() vim.opt.wrap = not vim.opt.wrap:get() end
        '';
        mode = "n";
      }

      # avoid typing W instead of w to save
      {
        key = "W";
        action = "w";
        mode = "ca";
      }
    ]
    ++ (
      let
        delta = 2;
        # use arrows to resize windows
        mkResize = key: side: delta: {
          key = "<${key}>";
          action = lib'.mkRaw "function() vim.api.nvim_win_set_${side}(0, vim.api.nvim_win_get_${side}(0) + (${toString delta})) end";
          mode = "n";
        };
      in
      [
        (mkResize "Up" "height" delta)
        (mkResize "Down" "height" (-delta))
        (mkResize "Left" "width" delta)
        (mkResize "Right" "width" (-delta))
      ]
    )
    ++ (
      # move to the split in the direction shown, or create a new split
      # uses custom WinMove function defined in extraConfigLuaPre
      let
        mkWinMove = key: {
          key = "<C-${key}>";
          action = lib'.mkRaw "WinMove('${key}')";
          mode = "n";
        };
      in
      map mkWinMove [
        "h"
        "j"
        "k"
        "l"
      ]
    );

    autoCmd = [
      # restore last cursor position when opening buffer (file)
      {
        event = "BufReadPost";
        pattern = "";
        callback = lib'.mkRaw ''
          function()
            vim.api.nvim_exec('silent! normal! g`"zv', false)
          end
        '';
      }
      # don't save cursor position when writing git commit messages
      {
        event = "BufReadPost";
        pattern = "COMMIT_EDITMSG";
        callback = lib'.mkRaw ''
          function()
            vim.opt_local.viminfofile = "NONE"
          end
        '';
      }

      # highlight yank'ed text
      {
        event = "TextYankPost";
        callback = lib'.mkRaw ''
          function()
            vim.hl.on_yank({ higroup = "IncSearch", timeout = 1000, on_visual = true })
          end
        '';
      }
    ];

    userCommands = {
      # helper functions to quickly change indentation style
      Spaces = {
        command = lib'.mkRaw ''
          function(opts)
            local count = tonumber(opts.fargs[1])
            vim.opt.shiftwidth = count
            vim.opt.softtabstop = count
            vim.opt.tabstop = count
            vim.opt.expandtab = true
          end
        '';
        nargs = 1;
      };
      Tabs = {
        command = lib'.mkRaw ''
          function(opts)
            local count = tonumber(opts.fargs[1])
            vim.opt.shiftwidth = count
            vim.opt.softtabstop = count
            vim.opt.tabstop = count
            vim.opt.expandtab = false
          end
        '';
        nargs = 1;
      };
    };

    plugins = {
      # infer indent from file contents
      guess-indent.enable = true;

      web-devicons.enable = true;

      lualine = {
        enable = true;
        settings = {
          sections = {
            lualine_b = lib.optional git "diff";
            lualine_c = [
              (lib'.listToUnkeyedAttrs [
                "diagnostics"

                {
                  sources = [ "nvim_diagnostic" ];
                  symbols = {
                    error = ":";
                    warn = ":";
                    info = ":";
                    hint = ":";
                  };
                }
              ])
              {
                __unkeyed = "filename";
                file_status = true;
                path = 1;
              }
            ];
            lualine_x = [
              (lib'.mkRaw ''
                function()
                  local word_count = vim.fn.wordcount().visual_words
                  if word_count == nul then
                    word_count = vim.fn.wordcount().words
                  end

                  if word_count == 1 then
                    return tostring(word_count) .. " word"
                  end
                  return tostring(word_count) .. " words"
                end
              '')
              "encoding"
              {
                __unkeyed = "filetype";
                colored = false;
              }
            ];
          };
          inactive_sections = {
            lualine_c = [
              {
                __unkeyed = "filename";
                file_status = true;
                path = 1;
              }
            ];
            lualine_x = [
              "encoding"
              {
                __unkeyed = "filetype";
                colored = false;
              }
            ];
          };
          tabline = {
            lualine_a = [ "hostname" ];
            lualine_b = lib.optional git "branch";
            lualine_z = [
              {
                __unkeyed = "tabs";
                tabs_color = {
                  inactive = "TermCursor";
                  active = "ColorColumn";
                };
              }
            ];
          };
        };
      };
    };

    extraConfigLuaPre = # lua
      ''
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
      '';
  };
}
