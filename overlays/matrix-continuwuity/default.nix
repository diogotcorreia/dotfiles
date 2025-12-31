# Add patch for vulnerability
# https://github.com/continuwuity/continuwuity/security/advisories/GHSA-m5p2-vccg-8c9v
{ ... }:
(_: prev: {
  matrix-continuwuity = prev.matrix-continuwuity.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0001-validate-membership-events-returned-by-remote-server.patch
      ./0002-fix-Forbid-creators-in-power-levels.patch
    ];
  });
})
