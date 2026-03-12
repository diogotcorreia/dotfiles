# Configuration for Home Assistant (and related programs) on Feb
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant
{
  config,
  lib,
  pkgs,
  ...
}:
let
  hassDomain = "ha.feb.diogotc.com";

  mqttPort = lib.my.ports.mqtt;
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
      "mqtt"
      "tasmota"
    ];

    config = {
      homeassistant.name = "Xperience House";
    };

    customComponents = [
      (pkgs.my.hass-resol-km2.override {
        inherit (pkgs.unstable) buildHomeAssistantComponent;
      })
    ];
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users.iot = {
          acl = [ "readwrite #" ]; # allow read/write access to all topics
          hashedPassword = "$7$101$nT82g1HieqPNbN82$7q44zrzOHaT9Clft/Vt6w4G957NW/rft9aX41UHQC4I3m0pqeq3KlGHfKaSzmPnyWV4YKLtqwyDo5pR6pEp3fQ==";
        };
        port = mqttPort;
      }
    ];
  };

  networking.firewall.extraInputRules = ''
    ip saddr 192.168.20.0/22 tcp dport ${toString mqttPort} accept comment "MQTT from IoT subnet"
  '';

  modules.impermanence.directories = [
    config.services.mosquitto.dataDir
  ];
}
