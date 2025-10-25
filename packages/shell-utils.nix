# Various useful shell utilities
{ lib, pkgs, ... }:
let
  scripts = {
    copy = pkgs.writeShellScriptBin "copy" ''
      exec ${lib.getExe pkgs.xclip} -selection clipboard "$@"
    '';
    pasta = pkgs.writeShellScriptBin "pasta" ''
      exec ${lib.getExe pkgs.xclip} -selection clipboard -o "$@"
    '';
    whereisreal = pkgs.writeShellScriptBin "whereisreal" ''
      readlink -f $(whereis "$@" | cut -d ' ' -f2-)
    '';
    disable-lid = pkgs.writeShellScriptBin "disable-lid" ''
      systemd-inhibit --what=handle-lid-switch sleep infinity
    '';
    prettypath = pkgs.writeShellScriptBin "prettypath" ''
      echo "$PATH" | sed 's/:/\
      /g'
    '';
  };
in
pkgs.symlinkJoin {
  name = "dtc-shell-utils";
  paths = builtins.attrValues scripts;
}
