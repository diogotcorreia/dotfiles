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
      # ignore quickstart if discord can't start without updating
      ./0003-openasar-skip-quickstart-if-update-needed.diff
    ];
  });
}
