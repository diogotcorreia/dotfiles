# modules/services/nebula.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# nebula (VPN) configuration.

{ config, lib, secretsDir, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.services.nebula;
in {
  options.modules.services.nebula = {
    enable = mkEnableOption "nebula";
    cert = mkOption { # Required
      type = types.path;
      example = "/etc/nebula/host.crt";
      description = "Path to the host certificate.";
    };
    key = mkOption { # Required
      type = types.path;
      example = "/etc/nebula/host.key";
      description = "Path to the host key.";
    };
    isLighthouse = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a lighthouse.";
    };
    lighthouses = mkOption {
      type = types.listOf types.str;
      default = [ "192.168.100.1" ];
      description = ''
        List of IPs of lighthouse hosts this node should report to and query from. This should be empty on lighthouse
        nodes. The IPs should be the lighthouse's Nebula IPs, not their external IPs.
      '';
      example = [ "192.168.100.1" ];
    };
  };

  config = mkIf cfg.enable {
    # Automatically get nebulaCA from agenix
    age.secrets.nebulaCA.file = "${secretsDir}/nebulaCA.age";

    services.nebula.networks.nebula0 = {
      enable = true;
      ca = config.age.secrets.nebulaCA.path;
      cert = cfg.cert;
      key = cfg.key;
      isLighthouse = cfg.isLighthouse;
      lighthouses = cfg.lighthouses;
      # TODO support more firewall rules
      firewall.outbound = [{
        port = "any";
        proto = "any";
        host = "any";
      }];

      staticHostMap = { "192.168.100.1" = [ "146.59.199.128:4242" ]; };
    };
  };
}
