# hosts/hera/device-aliases.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Caddy configuration for device domain aliases (i.e. access local devices from outside the network)
{lib, ...}: let
  inherit (lib) fold optionalString recursiveUpdate;
  defineAlias = domain: target: {
    nebula ? false,
    extraProxyConfig ? null,
  }: {
    security.acme.certs.${domain} = {};

    services.caddy.virtualHosts.${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        ${optionalString nebula "import NEBULA"}
        reverse_proxy ${target} ${
          optionalString (extraProxyConfig != null) ''
            {
              ${extraProxyConfig}
            }''
        }
      '';
    };
  };

  mergeAliases = listOfAttrsets:
    fold (attrset: acc: recursiveUpdate attrset acc) {} listOfAttrsets;
in
  mergeAliases [
    (defineAlias "apollo.diogotc.com" "192.168.1.2:8080" {})
    (defineAlias "external.apollo.diogotc.com" "192.168.1.2:1337" {})
    (defineAlias "home.diogotc.com" "192.168.1.4:80" {})
    (defineAlias "router.hera.diogotc.com" "192.168.1.1:80" {nebula = true;})
    (defineAlias "ap-livingroom.hera.diogotc.com" "https://192.168.1.64:65443" {
      nebula = true;
      extraProxyConfig = ''
        transport http {
          tls
          tls_insecure_skip_verify
        }
      '';
    })
  ]
