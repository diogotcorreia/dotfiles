# Apply PR https://github.com/Alexays/Waybar/pull/5054 to waybar
{ ... }:
(_: prev: {
  waybar = prev.waybar.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      # https://github.com/Alexays/Waybar/commit/6bdafede071c2e18711bfb3804f852208debd48b
      # Slightly adapted to fix merge conflicts
      ./0001-add-icons-format-replacement.diff
    ];
  });
})
