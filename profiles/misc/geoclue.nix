# Geoclue2 configuration
{...}: {
  # Use https://beacondb.net/, since Mozilla's service has been shutdown
  # See https://github.com/mozilla/ichnaea/issues/2065
  services.geoclue2.geoProviderUrl = "https://beacondb.net/v1/geolocate";
}
