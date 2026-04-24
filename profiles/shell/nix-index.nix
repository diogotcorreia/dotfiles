# Setup nix-index with pre-built database
{
  config,
  inputs,
  lib,
  user,
  ...
}:
{
  home-manager.sharedModules = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  hm.programs.nix-index.enable = true;
  hm.programs.nix-index.enableFishIntegration = false;

  # based on https://github.com/nix-community/nix-index/blob/master/command-not-found.sh
  hm.programs.fish.interactiveShellInit = /* fish */ ''
    function fish_command_not_found
      set toplevel nixpkgs
      set cmd $argv[1]
      set attrs (string split "\n" (${
        lib.getExe config.home-manager.users.${user}.programs.nix-index.package
      } --minimal --no-group --type x --type s --whole-name --at-root "/bin/$cmd" | sort))
      set len (count $attrs)

      switch $len
        case 0
          echo "$cmd: command not found" >&2

        case 1
          echo "\
    The program '$cmd' is currently not installed. You can run it once
    by typing:
      nix shell $toplevel#$attrs[0] -c $cmd ...\
    " >&2

        case '*'
          echo "\
    The program '$cmd' is currently not installed. It is provided by
    several packages. You can run it once by typing one of the following:\
    " >&2
          for attr in $attrs
            echo "  nix shell $toplevel#$attr -c $cmd ..." >&2
          end
      end

        return 127
    end
  '';
}
