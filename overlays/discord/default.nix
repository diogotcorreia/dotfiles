# Enable OpenASAR for Discord
# Additionally, add a patch to allow to declaratively set settings
{...}: final: prev: {
  discord-openasar = prev.discord.override {
    withOpenASAR = true;
  };
  openasar = prev.openasar.overrideAttrs (oldAttrs: {
    patches = [
      ./0001-openasar-override-settings-file.diff
      ./0002-openasar-allow-skip-quickstart.diff
    ];
  });
}
