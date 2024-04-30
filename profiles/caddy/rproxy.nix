# Reverse proxy of local ports for misc use, which require a public IP
# and/or HTTPS (i.e. proxying from a laptop using SSH)
{lib, ...}: let
  inherit (builtins) attrNames listToAttrs;
  inherit (lib) mapAttrs' nameValuePair pipe;

  ports = {
    "0" = 44380;
    "1" = 44381;
    "2" = 44382;
  };

  domainSuffix = ".rproxy.diogotc.com";
in {
  security.acme.certs = pipe ports [
    attrNames
    (map (name: nameValuePair "${name}${domainSuffix}" {}))
    listToAttrs
  ];

  services.caddy.virtualHosts =
    mapAttrs'
    (name: port:
      nameValuePair "${name}${domainSuffix}" {
        useACMEHost = "${name}${domainSuffix}";
        extraConfig = ''
          reverse_proxy localhost:${toString port}
        '';
      })
    ports;
}
