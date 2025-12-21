# Upgrade to unstable commit to fix zero day
# https://fedi.transgender.ing/notes/agj9mne73ias00d8
{ ... }:
(_: prev: {
  matrix-continuwuity = prev.matrix-continuwuity.overrideAttrs (oldAttrs: rec {
    # version = "unstable-2025-12-21";
    # src = prev.fetchFromGitea {
    #   domain = "forgejo.ellis.link";
    #   owner = "continuwuation";
    #   repo = "continuwuity";
    #   rev = "7fa4fa98628593c1a963f5aa8dbc3657d604b047";
    #   hash = "sha256-HIajaptQe3pTE+c5lDr2yQO5FG4NyZ2GU88d8AWJ0Eg=";
    # };
    #
    # cargoDeps = prev.rustPlatform.fetchCargoVendor {
    #   inherit src;
    #
    #   name = "${oldAttrs.pname}-${oldAttrs.version}";
    #   hash = "sha256-LHJLgo71iA0BTs754L8+twLBBi4jbYrQiBFe8om171U=";
    # };
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0001-fix-Apply-additional-validation-to-invites.patch
      ./0002-fix-Also-check-sender-origin.patch
    ];
  });
})
