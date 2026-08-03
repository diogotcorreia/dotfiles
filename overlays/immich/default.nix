# Apply patches to immich
{ ... }:
_final: prev: {
  # TODO 26.11: use package from stable
  immich = prev.unstable.immich.overrideAttrs (oldAttrs: {
    src = prev.applyPatches {
      inherit (oldAttrs) src;
      patches = [
        # Avoid downloading archives to RAM first
        # https://github.com/immich-app/immich/pull/30021
        ./0001-download-archive-html-forms-pr-30021.diff
      ];
    };
  });
}
