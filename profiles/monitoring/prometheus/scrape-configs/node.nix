{
  lib,
  nixosConfigurations,
  relabelInstance,
  relabelInstanceRegex,
  ...
}:
let
  hosts = lib.my.filterHosts [
    (cfg: cfg.services.prometheus.exporters.node.enable)
  ] nixosConfigurations;

  targets = [
    (config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}")
  ];
in
{
  static_configs = lib.my.mkStaticConfigs hosts targets;
  relabel_configs = relabelInstance ++ relabelInstanceRegex;
}
