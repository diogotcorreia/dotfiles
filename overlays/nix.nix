# Hot fix for curl in nix breaking with netrc
# https://github.com/NixOS/nixpkgs/pull/356133
{...}: final: prev: let
  patched-curl = prev.curl.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      # https://github.com/curl/curl/issues/15496
      (prev.fetchpatch {
        url = "https://github.com/curl/curl/commit/f5c616930b5cf148b1b2632da4f5963ff48bdf88.patch";
        hash = "sha256-FlsAlBxAzCmHBSP+opJVrZG8XxWJ+VP2ro4RAl3g0pQ=";
      })
      # https://github.com/curl/curl/issues/15513
      (prev.fetchpatch {
        url = "https://github.com/curl/curl/commit/0cdde0fdfbeb8c35420f6d03fa4b77ed73497694.patch";
        hash = "sha256-WP0zahMQIx9PtLmIDyNSJICeIJvN60VzJGN2IhiEYv0=";
      })
    ];
  });
in {
  nix = prev.nix.override (old: {
    curl = patched-curl;
  });
}
