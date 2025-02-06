# Common configuration for nginx reverse proxy
{lib, ...}: {
  # Open firewall ports
  networking.firewall.allowedTCPPorts = with lib.my.ports; [http https];

  services.nginx = {
    enable = true;

    # enable compression
    recommendedZstdSettings = true;
    recommendedGzipSettings = true;
    recommendedBrotliSettings = true;

    # other recommended settings
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;

    # reload instead of restarting whenever possible
    # https://github.com/NixOS/nixpkgs/issues/349604
    enableReload = true;
  };
}
