# Configuration for Grocy (https://github.com/grocy/grocy).
{ config, ... }:
let
  domain = "grocy.diogotc.com";

  dataDir = config.services.grocy.dataDir;
in
{
  services.grocy = {
    enable = true;

    hostName = domain;
    nginx.enableSSL = true;

    settings = {
      culture = "en";
      currency = "SEK";
      calendar = {
        firstDayOfWeek = 1;
        showWeekNumber = true;
      };
    };
  };

  # Allow uploading instruction manuals
  services.nginx.virtualHosts.${domain}.extraConfig = ''
    client_max_body_size 100M;
  '';

  modules.impermanence.directories = [ dataDir ];

  modules.services.restic.paths = [ dataDir ];
}
