# modules/services/dnsovertls.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Local DNS proxy server to use DNS over TLS.
# Inspired by luishfonseca's config.

{ pkgs, config, lib, utils, user, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf optionalString;
  cfg = config.modules.services.dnsovertls;
in {
  options.modules.services.dnsovertls = {
    enable = mkEnableOption "DNS over TLS proxy";
    name = mkOption {
      type = types.str;
      description = "DNS server name";
      default = "one.one.one.one";
    };
    ip = mkOption {
      type = types.str;
      description = "DNS server IP";
      default = "1.1.1.1";
    };
    cache = mkOption {
      type = types.int;
      default = 0;
      description = "Cache TTL in seconds";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = [ "127.0.0.53" ];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.coredns = {
      enable = true;
      config = ''
        . {
            bind 127.0.0.53
            ${optionalString (cfg.cache != 0) "cache ${toString cfg.cache}"}
            forward . tls://${cfg.ip} {
                tls_servername ${cfg.name}
            }
        }
      '';
    };
  };
}
