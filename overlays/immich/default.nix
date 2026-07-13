# Apply patches to immich
{ ... }:
_final: prev: {
  # TODO 26.11: use package from stable
  immich = prev.unstable.immich.overrideAttrs (oldAttrs: {
    src = prev.applyPatches {
      inherit (oldAttrs) src;
      patches = [
        # Add wakelock when uploading via web interface
        # https://github.com/immich-app/immich/pull/29820
        ./0001-wakelock-upload-web.diff
      ];
    };
  });
}
