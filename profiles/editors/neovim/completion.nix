{ ... }:
{
  hm.programs.nixvim = {
    plugins.blink-cmp = {
      enable = true;

      settings = {
        keymap.preset = "enter";

        completion = {
          documentation.auto_show = true;
          list.selection.preselect = false;
        };

        signature.enabled = true;

        sources = {
          default = [
            # defaults
            "lsp"
            "buffer"
            "omni"
            "path"

            # plugins
            "spell"
          ];

          providers = {
            spell = {
              name = "Spell";
              module = "blink-cmp-spell";
              score_offset = -100;
            };
          };
        };
      };
    };

    plugins.blink-cmp-spell.enable = true;
  };
}
