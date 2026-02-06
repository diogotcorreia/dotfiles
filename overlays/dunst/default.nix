# Fix https://github.com/dunst-project/dunst/issues/1492#issuecomment-3860088883
{ ... }:
(_: prev: {
  dunst = prev.dunst.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [ ] ++ [
      # https://github.com/dunst-project/dunst/commit/140ba4ff74c55f2e31419b720b989f5fa133914f
      # but modified so it applies to current version
      ./140ba4ff74c55f2e31419b720b989f5fa133914f.patch
    ];
  });
})
