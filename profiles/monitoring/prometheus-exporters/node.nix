{ lib, ... }:
let
  port = lib.my.ports.prometheus-node-exporter;
in
{
  services.prometheus.exporters.node = {
    enable = true;
    inherit port;
  };

  modules.services.nebula.firewall.inbound = [
    {
      inherit port;
      proto = "tcp";
      group = "uptime";
    }
  ];
}
