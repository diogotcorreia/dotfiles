# Use nightly version of ironbar because it supports niri workspaces
# TODO: remove on NixOS 25.05 (hopefully they will have made a release by then)
{...}: final: prev: {
  ironbar = prev.ironbar.overrideAttrs (oldAttrs: rec {
    version = "0-unstable-2025-03-27";
    src = prev.fetchFromGitHub {
      owner = "JakeStanger";
      repo = "ironbar";
      rev = "v${version}";
      hash = "sha256-UtBO1XaghmzKv9qfhfoLi4ke+mf+Mtgh4f4UpCeEVDg=";
    };

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-l+Y/ntuqaasDL0cEHSwscFxAs1jC0bm9oTU0J/K60AY=";
    };

    buildInputs =
      oldAttrs.buildInputs
      ++ [
        prev.libdbusmenu-gtk3
      ];
  });
}
