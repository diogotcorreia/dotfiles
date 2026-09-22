# Fix incorrect librespot patch
# https://github.com/NixOS/nixpkgs/pull/564869
{ ... }:
(_: prev: {
  unstable = prev.unstable // {
    music-assistant = prev.unstable.music-assistant.overrideAttrs (prevAttrs: {
      patches =
        (builtins.filter (p: !prev.lib.hasSuffix "librespot.patch" (toString p)) prevAttrs.patches)
        ++ [
          ./librespot.patch
        ];
    });
  };
})
