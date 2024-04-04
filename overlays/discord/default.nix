# Enable OpenASAR for Discord
# Additionally, add a patch to allow to declaratively set settings
{inputs, ...}: final: prev: rec {
  discord-openasar = prev.discord.override {
    withOpenASAR = true;
    openasar = let
      openasarPkg = prev.callPackage (inputs.nixpkgs
        + "/pkgs/applications/networking/instant-messengers/discord/openasar.nix")
      {};
    in
      openasarPkg.overrideAttrs (oldAttrs: rec {
        patches = [
          ./0001-openasar-override-settings-file.diff
          ./0002-openasar-allow-skip-quickstart.diff
        ];
      });
  };
}
