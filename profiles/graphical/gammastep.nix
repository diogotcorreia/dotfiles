{ config, ... }:
{
  hm.services.gammastep = {
    enable = true;
    inherit (config.location) provider latitude longitude;
  };
}
