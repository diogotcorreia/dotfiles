# Configuration for Home Assistant (and related programs) on Hera
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hassDomain = "hass.diogotc.com";
  hassPort = hassCfg.config.http.server_port;

  mqttPort = lib.my.ports.mqtt;

  hassCfg = config.services.home-assistant;
in
{
  # https://github.com/esphome/issues/issues/2669
  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.igmp_max_memberships" = 50;
        "net.ipv6.igmp_max_msf" = 30;
      };
    };
  };

  services.home-assistant = {
    enable = true;

    # Custom options
    useSensibleDefaults = true;
    usePostgresql = true;
    externalDomain = hassDomain;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = [
      "cast"
      "esphome"
      "ipp"
      "met"
      "mqtt"
      "music_assistant"
      "shelly"
      "spotify"
      "synology_dsm"
      "systemmonitor"
      "tasmota"
      "telegram_bot"
      "upnp"
      "wake_on_lan"
      "yeelight"
    ];

    customComponents = [
      (pkgs.my.spotcast.override {
        inherit (pkgs.unstable) buildHomeAssistantComponent;
        home-assistant = hassCfg.package;
      })
    ];

    customLovelaceModules = with pkgs.unstable.home-assistant-custom-lovelace-modules; [
      mini-graph-card
    ];

    config = {
      rest_command = {
        push_position_to_dawarich = {
          url = "https://${config.services.dawarich.localDomain}/api/v1/owntracks/points";
          headers = {
            authorization = "Bearer {{ api_key }}";
          };
          method = "POST";
          content_type = "application/json";
          payload = ''{"tst": {{ as_timestamp(now()) }},"_type": "location","lat": {{ latitude }},"lon": {{ longitude }},"acc": {{ gps_accuracy }},"alt": {{ altitude }},"vac": {{ vertical_accuracy }},"vel": {{ velocity }},"cog": {{ course }},"batt": {{ battery_level }},"bs": {{ battery_status }},"inregions": ["{{ zone }}"],"t": "u","SSID": "{{ wifi_ssid }}"}'';
        };
      };

      wake_on_lan = { };
      "switch wol" = "!include switch-wol.yaml";
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          homeassistant = {
            acl = [ "readwrite #" ]; # allow read/write access to all topics
            hashedPassword = "$7$101$jAxZzJhHWgYUIXkW$/KSUVrG2ABwJifO7Qj9nSFbfRvdhQ4e7nJHNcxd4YK1jnKlllIJtog3VEgdtXiMnKzHyIDsIeiUv76EakaSHjA==";
          };
          mqtt_devices = {
            acl = [ "readwrite #" ]; # allow read/write access to all topics
            hashedPassword = "$7$101$N0xrlJHorZ4ACqpI$HPs/OppCXgXDxaFJZTFNLYUHi1oGrrsYpXyTyoX3QZ0jWADSQTf4ZvZHVl4xKxu3SI5padp7cdo4Xjpt87Vf7Q==";
          };
        };
        port = mqttPort;
      }
    ];
  };

  networking.firewall = {
    # UDP Port for mDNS discovery of Google Cast devices (Spotify)
    # UDP Port for CoIoT (Shelly push)
    allowedUDPPorts = with lib.my.ports; [
      coiot
      mdnsGoogleCast
    ];

    allowedTCPPorts = with lib.my.ports; [
      hassPort
      mqttPort
      musicAssistantAudioStream
      musicAssistantWeb
    ];
  };

  modules.impermanence.directories = [
    config.services.mosquitto.dataDir
  ];
}
