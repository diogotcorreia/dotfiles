# Common configuration for nginx reverse proxy
{...}: {
  # Open firewall ports
  networking.firewall.allowedTCPPorts = [80 443];

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
