{config, ...}: let
  port = 8033;

  stateDir = "/var/lib/${config.services.prometheus.stateDir}";
in {
  services.prometheus = {
    inherit port;

    enable = true;
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {targets = ["localhost:${toString port}"];}
        ];
      }
    ];
  };
}
