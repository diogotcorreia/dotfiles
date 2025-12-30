# Various useful shell utilities
{ lib, pkgs, ... }:
let
  scripts = {
    copy = pkgs.writeShellScriptBin "copy" ''
      exec ${lib.getExe' pkgs.wl-clipboard "wl-copy"} "$@"
    '';
    pasta = pkgs.writeShellScriptBin "pasta" ''
      exec ${lib.getExe' pkgs.wl-clipboard "wl-paste"} --no-newline "$@"
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
