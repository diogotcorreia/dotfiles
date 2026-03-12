{ profiles, ... }:
{
  imports = with profiles; [
    # extend common
    meta.common

    monitoring.prometheus-exporters.node
    networking.dnsovertls
  ];

  # Use a modern network configuration backend instead of legacy scripts
  networking.useNetworkd = true;
}
