# Configuration for Home Assistant (and related programs) on Bro
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant
{
  pkgs,
  config,
  ...
}: let
  hassDomain = "ha.bro.diogotc.com";
  hassPort = hassCfg.config.http.server_port;

  mqttPort = 1883;

  hassCfg = config.services.home-assistant;
in {
  services.home-assistant = {
    enable = true;

    # Custom options
    useSensibleDefaults = true;
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
      zha.zigpy_config.ota.ikea_provider = true;
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
          acl = ["readwrite #"]; # allow read/write access to all topics
          hashedPassword = "$7$101$zKBywp7+zF4mY2Ob$Nnka6+eUPvskhwcgsuUWR5fgwuOKj1YA5TsZ1biJjfJDLkIJFtHnm0zEdqQ6x8PVUfGmuc50HXCN17KHbTQNIw==";
        };
        port = mqttPort;
      }
    ];
  };

  networking.firewall.interfaces = {
    vlan-private = {
      # UDP Port 5353 for mDNS discovery of Google Cast devices (Spotify)
      allowedUDPPorts = [5353];

      allowedTCPPorts = [hassPort];
    };
    vlan-iot-local = {allowedTCPPorts = [mqttPort];};
  };

  modules.impermanence.directories = [
    config.services.mosquitto.dataDir
  ];
}
