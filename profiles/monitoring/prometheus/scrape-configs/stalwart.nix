{
  lib,
  nixosConfigurations,
  relabelInstance,
  ...
}:
let
  hosts = lib.my.filterHosts [
    (cfg: cfg.services.stalwart.enable)
    (cfg: cfg.services.stalwart.settings.metrics.prometheus.enable or false)
  ] nixosConfigurations;

  targets = [
    (config: config.services.stalwart.settings.metrics.prometheus.host)
  ];
in
{
  static_configs = lib.my.mkStaticConfigs hosts targets;
  relabel_configs = relabelInstance;

  scheme = "https";
  metrics_path = "/metrics/prometheus";
}
