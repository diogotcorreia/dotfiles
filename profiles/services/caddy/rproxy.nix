# Reverse proxy of local ports for misc use, which require a public IP
# and/or HTTPS (i.e. proxying from a laptop using SSH)
{lib, ...}: let
  inherit (lib) mapAttrs' nameValuePair;

  ports = with lib.my.ports; {
    "0" = rproxy0;
    "1" = rproxy1;
    "2" = rproxy2;
  };

  domainSuffix = ".rproxy.diogotc.com";
in {
  services.caddy.virtualHosts =
    mapAttrs'
    (name: port:
      nameValuePair "${name}${domainSuffix}" {
        enableACME = true;
        extraConfig = ''
          reverse_proxy localhost:${toString port}
        '';
      })
    ports;
}
