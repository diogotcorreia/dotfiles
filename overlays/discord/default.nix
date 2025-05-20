# Enable OpenASAR for Discord
# Additionally, add a patch to allow to declaratively set settings
{...}: _final: prev: {
  discord-openasar = prev.discord.override {
    withOpenASAR = true;
  };
  openasar = prev.openasar.overrideAttrs (_oldAttrs: {
    patches = [
      ./0001-openasar-override-settings-file.diff
      ./0002-openasar-allow-skip-quickstart.diff
    ];
  });
}
