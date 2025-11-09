{ ... }:
{
  hm.programs.nixvim = {
    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>b" = "buffers ignore_current_buffer=true sort_mru=true";
        "<leader>c" = "commands";
        # <leader>f is defined below, as it searches for git files when in a repo, but files otherwise
        "<leader>gs" = "git_status";
        "<leader>m" = "manix";
        "<leader>o" = "find_files";
        "<leader>rg" = "live_grep";
      };

      extensions = {
        fzf-native.enable = true;
        manix.enable = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>f";
        action.__raw = "telescope_project_files()";
        options.desc = "Telescope find files";
      }
    ];

    extraConfigLuaPre = # lua
      ''
        -- Helper for telescope (<leader>f)
        function telescope_project_files()
          -- We cache the results of "git rev-parse"
          local is_inside_work_tree = {}

          local opts = {}

          return function()
            local cwd = vim.fn.getcwd()
            if is_inside_work_tree[cwd] == nil then
              vim.fn.system("git rev-parse --is-inside-work-tree")
              is_inside_work_tree[cwd] = vim.v.shell_error == 0
            end

            if is_inside_work_tree[cwd] then
              require("telescope.builtin").git_files(opts)
            else
              require("telescope.builtin").find_files(opts)
            end
          end
        end
      '';
  };
}
