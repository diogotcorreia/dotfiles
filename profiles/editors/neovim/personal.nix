{ profiles, ... }:
{
  imports = with profiles; [
    editors.neovim.base
    editors.neovim.lsp
  ];
}
