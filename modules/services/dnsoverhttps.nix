# Local DNS proxy server to use Cloudflare's DNS over HTTPS.
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.modules.services.dnsoverhttps;

  # https://dnscrypt.info/stamps/
  upstreams = [
    "sdns://AgcAAAAAAAAABzEuMS4xLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5" # 1.1.1.1
    "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5" # 1.0.0.1
    "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTExMV0AIDFkb3QxZG90MWRvdDEuY2xvdWRmbGFyZS1kbnMuY29tCi9kbnMtcXVlcnk" # [2606:4700:4700::1111]
    "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTAwMV0AIDFkb3QxZG90MWRvdDEuY2xvdWRmbGFyZS1kbnMuY29tCi9kbnMtcXVlcnk" # [2606:4700:4700::1001]
  ];
in {
  options.modules.services.dnsoverhttps = {
    enable = mkEnableOption "Cloudflare DNS over HTTPS proxy";

    all-interfaces = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether the dns proxy should listen on all interfaces or
        only on the loopback interface.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = ["127.0.0.53"];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.dnsproxy = {
      enable = true;
      settings = {
        upstream = upstreams;
        listen-addrs = [
          (
            if cfg.all-interfaces
            then "0.0.0.0"
            else "127.0.0.53"
          )
        ];
      };
      flags = ["--cache"];
    };
  };
}
