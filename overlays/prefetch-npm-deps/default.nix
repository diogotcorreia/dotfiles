# Apply patches to prefetch-npm-deps
{ ... }:
_final: prev: {
  prefetch-npm-deps-patched = prev.prefetch-npm-deps.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0001-ignore-local-files.diff
    ];
  });
}
