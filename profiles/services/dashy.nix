# Dashy dashboard configuration
{...}: let
  domain = "dash.diogotc.com";

  mkUrl = subdomain: "https://${subdomain}.diogotc.com";

  # Icons from: https://github.com/homarr-labs/dashboard-icons
  items = {
    authelia = {
      title = "Authelia";
      icon = "hl-authelia";
      description = "Single Sign-On Authentication";
      url = mkUrl "auth";
    };
    battleships = {
      title = "Battleships";
      icon = ":ship:";
      description = "A self-made battleships two player online game";
      url = mkUrl "battleships";
    };
    bazarr = {
      title = "Bazarr";
      icon = "hl-bazarr";
      description = "Subtitle manager for the arr-stack";
      url = mkUrl "bazarr.hera";
    };
    calibre-web = {
      title = "Calibre Web";
      icon = "hl-calibre";
      description = "Manage books and send them to e-readers";
      url = mkUrl "calibre";
    };
    chhoto-url = {
      title = "Chhoto URL";
      icon = ":link:";
      description = "Link shortner";
      url = mkUrl "s";
    };
    dawarich = {
      title = "Dawarich";
      icon = ":world_map:";
      description = "Location history";
      url = mkUrl "location";
    };
    element = {
      title = "Element";
      icon = "hl-element";
      description = "Web chat client for Matrix";
      url = mkUrl "chat";
    };
    firefly-iii = {
      title = "Firefly III";
      icon = "hl-firefly";
      description = "Personal finance manager";
      url = mkUrl "firefly3";
    };
    firefly-iii-data-importer = {
      title = "Firefly III Data Importer";
      icon = "hl-firefly";
      description = "Import data from banks and CSV files into Firefly III";
      url = mkUrl "firefly3-csv";
    };
    grocy = {
      title = "Grocy";
      icon = "hl-grocy";
      description = "Fridge and cupboard stock manager";
      url = mkUrl "grocy";
    };
    healthchecks-io = {
      title = "Healthchecks.io";
      icon = "hl-healthchecks";
      description = "Monitoring of cronjobs and scheduled tasks";
      url = mkUrl "healthchecks";
    };
    home-assistant-bro = {
      title = "Home Assistant (Stockholm)";
      icon = "hl-home-assistant";
      description = "Smart home automation and dashboard";
      url = mkUrl "ha.bro";
    };
    home-assistant-feb = {
      title = "Home Assistant (Janeiro)";
      icon = "hl-home-assistant";
      description = "Smart home automation and dashboard";
      url = mkUrl "ha.feb";
    };
    home-assistant-hera = {
      title = "Home Assistant (Lisbon)";
      icon = "hl-home-assistant";
      description = "Smart home automation and dashboard";
      url = mkUrl "hass";
    };
    immich = {
      title = "Immich";
      icon = "hl-immich";
      description = "Photo and video library and backup";
      url = mkUrl "photos";
    };
    jackett = {
      title = "Jackett";
      icon = "hl-jackett";
      description = "Torrent tracker";
      url = mkUrl "jackett.hera";
    };
    jellyfin = {
      title = "Jellyfin";
      icon = "hl-jellyfin";
      description = "Movies, TV shows and live TV player";
      url = mkUrl "jellyfin";
    };
    jellyseerr = {
      title = "Jellyseerr";
      icon = "hl-jellyseerr";
      description = "Media request and discovery manager for Jellyfin";
      url = mkUrl "jellyseerr";
    };
    karaoke = {
      title = "Karaoke Song List";
      icon = ":microphone:";
      description = "List of songs in my ultrastar-deluxe's collection";
      url = mkUrl "karaoke";
    };
    nextcloud = {
      title = "Nextcloud";
      icon = "hl-nextcloud";
      description = "Files, calendar, todo-list, notes, and more";
      url = mkUrl "cloud";
    };
    nodered = {
      title = "Node-RED";
      icon = "hl-node-red";
      description = "Flow-based automation";
      url = mkUrl "nodered.hera";
    };
    pairdrop = {
      title = "PairDrop";
      icon = "hl-snapdrop";
      description = "Peer-to-peer file/text transfer";
      url = mkUrl "drop";
    };
    paperless-ngx = {
      title = "Paperless-ngx";
      icon = "hl-paperless-ngx";
      description = "Document management system";
      url = mkUrl "paperless";
    };
    radarr = {
      title = "Radarr";
      icon = "hl-radarr";
      description = "Movie manager for the arr-stack";
      url = mkUrl "radarr.hera";
    };
    reposilite = {
      title = "Reposilite";
      icon = "hl-java";
      description = "Maven repository";
      url = mkUrl "repo";
    };
    sonarr = {
      title = "Sonarr";
      icon = "hl-sonarr";
      description = "TV series manager for the arr-stack";
      url = mkUrl "sonarr.hera";
    };
    transmission = {
      title = "Transmission";
      icon = "hl-flood";
      description = "Torrent downloader";
      url = mkUrl "transmission.hera";
    };
    umami = {
      title = "Umami";
      icon = "hl-umami";
      description = "Web analytics";
      url = mkUrl "umami";
    };
    uptime-kuma = {
      title = "Uptime Kuma";
      icon = "hl-uptime-kuma";
      description = "Website uptime monitoring";
      url = mkUrl "uptime";
    };
    wastebin = {
      title = "wastebin";
      icon = ":page_with_curl:";
      description = "Text paste service";
      url = mkUrl "bin";
    };
  };
in {
  services.dashy = {
    enable = true;

    virtualHost = {
      enableNginx = true;
      inherit domain;
    };

    settings = {
      appConfig = {
        theme = "nord-frost";
        layout = "auto";
        iconSize = "large";
        language = "en";
        disableUpdateChecks = true;
        hideComponents = {
          hideSettings = true;
        };
      };
      pageInfo = {
        title = "Diogo's Homelab";
        description = "Collection of my self-hosted services";
      };
      sections = [
        {
          name = "Featured";
          icon = ":star2:";
          displayData = {
            cols = 4;
          };
          items = with items; [
            home-assistant-hera
            immich
            nextcloud
            jellyfin
            jellyseerr
            calibre-web
            paperless-ngx
          ];
        }
        {
          name = "Media & Entertainment";
          icon = ":tv:";
          items = with items; [
            jellyfin
            jellyseerr
            immich
            calibre-web
            radarr
            sonarr
            bazarr
            jackett
            transmission
          ];
        }
        {
          name = "Productivity & Personal";
          icon = ":ledger:";
          items = with items; [
            nextcloud
            paperless-ngx
            firefly-iii
            firefly-iii-data-importer
            dawarich
          ];
        }
        {
          name = "Sharing";
          icon = ":envelope_with_arrow:";
          items = with items; [
            chhoto-url
            pairdrop
            wastebin
          ];
        }
        {
          name = "Home Control & Management";
          icon = ":house:";
          items = with items; [
            grocy
            home-assistant-hera
            home-assistant-bro
            home-assistant-feb
          ];
        }
        {
          name = "System Monitoring";
          icon = ":chart_with_upwards_trend:";
          items = with items; [
            healthchecks-io
            uptime-kuma
            umami
          ];
        }
        {
          name = "Security";
          icon = ":closed_lock_with_key:";
          items = with items; [
            authelia
          ];
        }
        {
          name = "Social";
          icon = ":speech_balloon:";
          items = with items; [
            element
          ];
        }
        {
          name = "Code";
          icon = ":keyboard:";
          items = with items; [
            reposilite
          ];
        }
        {
          name = "Miscellaneous";
          icon = ":question:";
          items = with items; [
            battleships
            karaoke
          ];
        }
      ];
    };
  };

  services.nginx.virtualHosts.${domain}.enableACME = true;
}
