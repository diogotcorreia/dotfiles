{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  lib' = config.home-manager.users.${user}.lib.nixvim;
in
{
  hm.programs.nixvim = {
    lsp = {
      inlayHints.enable = true;

      servers = {
        # Astro
        astro.enable = true;
        # C/C++
        ccls.enable = true;
        # HTML
        html.enable = true;
        # JS/TS
        ts_ls.enable = true;
        # Nix
        nil_ls = {
          enable = true;
          settings = {
            settings.nil.formatting.command = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
          };
        };
        # Python
        pylsp.enable = true;
        ruff.enable = true;
        # Rust is handled by rustaceanvim
        # Typst
        tinymist = {
          enable = true;
          settings = {
            settings = {
              exportPdf = "never";
              formatterMode = "typstyle";
            };

            # Add keybind to launch typst watch and PDF viewer for current file, and set the current buffer as the main file on tinymist lsp
            on_attach = lib'.mkRaw /* lua */ ''
              function(client, bufnr)
                vim.keymap.set("n", "<leader>tw", function()
                  vim.fn['typst#TypstWatch']()
                  client:exec_cmd({
                    title = "pin",
                    command = "tinymist.pinMain",
                    arguments = { vim.api.nvim_buf_get_name(0) },
                  }, { bufnr = bufnr })
                end, { desc = "Typst Watch", noremap = true })
              end
            '';
          };
        };
      };

      keymaps = [
        {
          key = "<leader>tt";
          lspBufAction = "format";
        }
        {
          key = "<leader>d";
          lspBufAction = "definition";
        }
        {
          key = "<leader>gr";
          lspBufAction = "references";
        }
        {
          key = "<leader>gt";
          lspBufAction = "type_definition";
        }
        {
          key = "<leader>gi";
          lspBufAction = "implementation";
        }
        {
          key = "<leader>rn";
          lspBufAction = "rename";
        }
        {
          key = "<leader>a";
          lspBufAction = "code_action";
        }
        {
          key = "<leader>n";
          action = lib'.mkRaw "function() vim.diagnostic.goto_next({ wrap=false }) end";
        }
        {
          key = "<leader>p";
          action = lib'.mkRaw "function() vim.diagnostic.goto_prev({ wrap=false }) end";
        }
        {
          key = "<leader><cr>";
          action = lib'.mkRaw "vim.diagnostic.open_float";
        }
        {
          key = "<leader>gn";
          action = lib'.mkRaw "require('illuminate').goto_next_reference";
        }
        {
          key = "<leader>gp";
          action = lib'.mkRaw "require('illuminate').goto_prev_reference";
        }
      ];
    };

    plugins.lspconfig.enable = true;
    plugins.illuminate.enable = true;

    plugins.treesitter = {
      enable = true;
      folding = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };

      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        astro
        bash
        c
        comment
        cpp
        html
        java
        javascript
        json
        lua
        make
        markdown
        nix
        python
        regex
        rust
        toml
        typescript
        typst
        vim
        vimdoc
        xml
        yaml
      ];
    };

    plugins.typst-vim.enable = true;
    dependencies.typst.enable = false; # use typst in path
    plugins.rustaceanvim.enable = true;
    dependencies.rust-analyzer.enable = false; # use rust-analyzer in path
  };

  hm.home.packages = with pkgs; [
    typstyle # Typst formatter
  ];
}
