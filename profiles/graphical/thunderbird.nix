# Thunderbird email client configuration
{...}: {
  hm.programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;

      # Use GPG keys already in the system
      withExternalGnupg = true;
    };
  };
}
