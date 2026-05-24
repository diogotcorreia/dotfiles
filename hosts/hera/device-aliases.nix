# Nginx configuration for device domain aliases (i.e. access local devices from outside the network)
{ lib, ... }:
let
  inherit (lib) foldr recursiveUpdate;
  defineAlias =
    domain: target:
    {
      nebula ? false,
      extraLocationConfig ? null,
    }:
    {
      services.nginx.virtualHosts.${domain} = {
        enableACME = true;
        restrictToNebula = nebula;
        locations."/" = {
          proxyPass = target;
          extraConfig = lib.mkIf (extraLocationConfig != null) extraLocationConfig;
        };
      };
    };

  mergeAliases = listOfAttrsets: foldr (attrset: acc: recursiveUpdate attrset acc) { } listOfAttrsets;
in
mergeAliases [
  (defineAlias "apollo.diogotc.com" "http://192.168.1.2:8080" { })
  (defineAlias "external.apollo.diogotc.com" "http://192.168.1.2:1337" { })
  (defineAlias "diskstation.hera.diogotc.com" "http://192.168.1.4:5000" { nebula = true; })
  (defineAlias "router.hera.diogotc.com" "http://192.168.1.1:80" { nebula = true; })
  (defineAlias "ap-livingroom.hera.diogotc.com" "https://192.168.1.64:65443" {
    nebula = true;
    # this device uses a self-signed cert and is severely outdated
    extraLocationConfig = ''
      proxy_ssl_verify off;
      proxy_ssl_conf_command Options UnsafeLegacyRenegotiation;
      proxy_ssl_ciphers DEFAULT@SECLEVEL=0;
    '';
  })
]
