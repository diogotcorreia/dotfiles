# Configuration for Home Assistant (and related programs) on Bro
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hassDomain = "ha.bro.diogotc.com";
  hassPort = hassCfg.config.http.server_port;

  massDomain = "ma.bro.diogotc.com";
  massPort = lib.my.ports.musicAssistantWeb;

  mqttPort = lib.my.ports.mqtt;

  hassCfg = config.services.home-assistant;
in
{
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
      "met"
      "mqtt"
      "tasmota"
      "zha"
    ];

    config = {
      zha.zigpy_config.ota.extra_providers = [
        { type = "ikea"; }
      ];
    };

    customComponents = [
      (pkgs.my.hasl3.override {
        inherit (pkgs.unstable) buildHomeAssistantComponent;
        home-assistant = hassCfg.package;
      })
    ];

    customZhaQuirks = with pkgs.my.home-assistant-custom-zha-quirks; [
      tuya-persence-sensor-ts0225
    ];
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users.iot = {
          acl = [ "readwrite #" ]; # allow read/write access to all topics
          hashedPassword = "$7$101$zKBywp7+zF4mY2Ob$Nnka6+eUPvskhwcgsuUWR5fgwuOKj1YA5TsZ1biJjfJDLkIJFtHnm0zEdqQ6x8PVUfGmuc50HXCN17KHbTQNIw==";
        };
        port = mqttPort;
      }
    ];
  };

  services.music-assistant = {
    enable = true;
    providers = [
      "builtin"
      "chromecast"
      "hass"
      "hass_players"
      "sendspin"
      "spotify"
      "spotify_connect"
      "universal_group"
    ];

    # Custom options
    useSensibleDefaults = true;
    externalDomain = massDomain;
  };

  networking.firewall.interfaces = {
    vlan-private = {
      # UDP Port 5353 for mDNS discovery of Google Cast devices (Spotify)
      allowedUDPPorts = [ lib.my.ports.mdnsGoogleCast ];

      allowedTCPPorts = [
        hassPort
        massPort
      ];
    };
    vlan-iot-local = {
      allowedTCPPorts = [ mqttPort ];
    };
  };

  modules.impermanence.directories = [
    config.services.mosquitto.dataDir
  ];
}
