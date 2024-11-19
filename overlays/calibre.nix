# Hotfix for build failure
# Remove once https://github.com/NixOS/nixpkgs/pull/356515 reaches nixos-24.11
{...}: final: prev: {
  calibre = prev.calibre.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
  });
}
