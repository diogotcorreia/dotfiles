# Application launcher
{ lib, ... }:
let
  toFuzzelColor = c: "${lib.substring 1 (-1) c}ff";
in
{
  hm.programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        list-executables-in-path = true;
      };

      colors = with lib.my.colors; {
        background = toFuzzelColor black;
        text = toFuzzelColor lightwhite;
        prompt = toFuzzelColor white;
        placeholder = toFuzzelColor darkwhite;
        input = toFuzzelColor lightwhite;
        match = toFuzzelColor red;
        selection = toFuzzelColor grey;
        selection-text = toFuzzelColor lightwhite;
        selection-match = toFuzzelColor red;
        counter = toFuzzelColor darkwhite;
        border = toFuzzelColor lightblue;
      };

      border.width = 2;
    };
  };
}
