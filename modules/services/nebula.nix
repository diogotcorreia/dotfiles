# nebula (VPN) configuration.
{
  config,
  lib,
  secrets,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.services.nebula;

  lighthouses = {
    "192.168.100.1" = ["zeus.diogotc.com:4242"];
    "192.168.100.7" = ["phobos.diogotc.com:4242"];
  };
in {
  options.modules.services.nebula = {
    enable = mkEnableOption "nebula";
    cert = mkOption {
      # Required
      type = types.path;
      example = "/etc/nebula/host.crt";
      description = "Path to the host certificate.";
    };
    key = mkOption {
      # Required
      type = types.path;
      example = "/etc/nebula/host.key";
      description = "Path to the host key.";
    };
    isLighthouse = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node is a lighthouse.";
    };

    firewall.outbound = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = lib.mdDoc "Firewall rules for outbound traffic.";
      example = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
    };
    firewall.inbound = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = lib.mdDoc "Firewall rules for inbound traffic.";
      example = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
    };
    firewall.allowPinging = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow ICMP pings to this node.";
    };
  };

  config = mkIf cfg.enable {
    # Automatically get nebulaCA from agenix
    age.secrets.nebulaCA = {
      file = secrets.nebulaCA;
      owner = "nebula-nebula0";
    };

    services.nebula.networks.nebula0 = {
      enable = true;
      ca = config.age.secrets.nebulaCA.path;
      cert = cfg.cert;
      key = cfg.key;
      isLighthouse = cfg.isLighthouse;
      isRelay = cfg.isLighthouse; # assume all lighthouses are relays as well
      lighthouses = lib.lists.optionals (!cfg.isLighthouse) (attrNames lighthouses);
      # listen on both ipv4 and ipv6
      listen.host = "[::]";

      firewall.outbound =
        [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ]
        ++ cfg.firewall.outbound;
      firewall.inbound =
        (lib.lists.optional cfg.firewall.allowPinging {
          port = "any";
          proto = "icmp";
          host = "any";
        })
        ++ cfg.firewall.inbound;

      staticHostMap = lighthouses;

      settings = {
        # punch through firewall NATs
        punchy = {
          punch = true;
          respond = true;
        };

        static_map = {
          # fetch both A and AAAA DNS records for lighthouses
          network = "ip";
        };

        lighthouse = {
          local_allow_list = {
            interfaces = {
              # don't advertise docker IPs to lighthouse
              "docker.*" = false;
              "br-[0-9a-f]{12}" = false;
            };
          };
        };

        relay = {
          relays = lib.lists.optionals (!cfg.isLighthouse) (builtins.attrNames lighthouses);
          use_relays = !cfg.isLighthouse;
        };
      };
    };
  };
}
