{ ... }:
{
  imports = [
    ./docker.nix
    ./git.nix
  ];

  hm.programs.fish = {
    functions = {
      __multicd = /* fish */ ''
        echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
      '';
    };

    shellAbbrs = {
      dotdot = {
        regex = ''^\.\.+$'';
        function = "__multicd";
      };
    };
  };
}
