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
        # Avoid downloading archives to RAM first
        # https://github.com/immich-app/immich/pull/30021
        ./0002-download-archive-html-forms-pr-30021.diff
        # Fix iOS Safari upload input
        # https://github.com/immich-app/immich/pull/29660
        (prev.fetchpatch {
          url = "https://github.com/immich-app/immich/commit/89d0a9d59f1b7ca2854ee76206ec0fa748867580.patch";
          hash = "sha256-YWfKL10eK89KcXKhu7ftD/aP3+rDGGQRvWDHEpWqFxE=";
        })
      ];
    };
  });
}
