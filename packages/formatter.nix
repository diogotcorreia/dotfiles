{
  deadnix,
  lib,
  nixfmt-tree,
  writeShellScriptBin,
  ...
}:
# https://github.com/NixOS/nix/pull/11438#issuecomment-2343378813
writeShellScriptBin "formatter" ''
  set -e

  OPTIND=1

  DEADNIX_ARGS=()
  NIXFMT_ARGS=()
  while getopts "c" opt; do
    case "$opt" in
      c)
        DEADNIX_ARGS+=("--fail")
        NIXFMT_ARGS+=("--ci")
        ;;
    esac
  done
  shift $((OPTIND-1))
  [ "''${1:-}" = "--" ] && shift

  # If no arguments are passed, default to formatting the whole project
  if [[ $# = 0 ]]; then
    prj_root=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
    set -- "$prj_root"
  fi

  "${lib.getExe deadnix}" --hidden --edit "''${DEADNIX_ARGS[@]}" -- "$@"
  "${lib.getExe nixfmt-tree}" "''${NIXFMT_ARGS[@]}" -- "$@"
''
