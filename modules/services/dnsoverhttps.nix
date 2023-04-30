# modules/services/dnsoverhttps.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Local DNS proxy server to use Cloudflare's DNS over HTTPS.

{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.services.dnsoverhttps;
in {
  options.modules.services.dnsoverhttps = {
    enable = mkEnableOption "Cloudflare DNS over HTTPS proxy";
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = [ "127.0.0.53" ];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        listen_addresses = [ "127.0.0.53:53" ];

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
          minisign_key =
            "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };

        server_names = [ "cloudflare" "cloudflare-ipv6" ];
      };
    };
  };
}
