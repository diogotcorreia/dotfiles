{
  config,
  lib,
  ...
}@args:
let
  port = lib.my.ports.prometheus;
  stateDir = "/var/lib/${config.services.prometheus.stateDir}";

  # Relabeling rules for Prometheus
  relabeling = {
    relabelInstance = [
      {
        source_labels = [ "__address__" ];
        target_label = "instance";
      }
    ];
    relabelInstanceRegex = [
      {
        source_labels = [ "instance" ];
        target_label = "instance";
        replacement = "\${1}";
        regex = "([^\.]+)\..+";
      }
    ];
  };

  extraArgs = { } // relabeling;

  mkScrapeConfigs =
    dir:
    lib.lists.flatten (
      lib.mapAttrsToList (
        path: _:
        let
          cfg' = import (dir + "/${path}") (args // extraArgs);
          cfgs = lib.toList cfg';
        in
        (builtins.map (cfg: ({ job_name = lib.removeSuffix ".nix" path; } // cfg)) cfgs)
      ) (builtins.readDir dir)
    );
in
{
  services.prometheus = {
    inherit port;
    listenAddress = "[::1]";

    enable = true;
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    scrapeConfigs = mkScrapeConfigs ./scrape-configs;
  };

  modules.impermanence.directories = [ stateDir ];
  modules.services.restic.paths = [ stateDir ];
}
