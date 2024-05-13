# Configuration for Home Assistant (and related programs) on Bro
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant
{
  inputs,
  pkgs,
  config,
  hostSecretsDir,
  ...
}: let
  hassDomain = "ha.bro.diogotc.com";
  hassPort = 8123;

  mqttPort = 1883;
in {
  age.secrets = {
    hassSecrets = {
      file = "${hostSecretsDir}/hassSecrets.age";
      path = "/persist/${config.services.home-assistant.configDir}/secrets.yaml";
      mode = "400";
      owner = "hass";
      group = "hass";
    };
  };

  disabledModules = ["services/home-automation/home-assistant.nix"];
  imports = [
    (inputs.nixpkgs-unstable
      + "/nixos/modules/services/home-automation/home-assistant.nix")
  ];
  services.home-assistant = let
    package = pkgs.unstable.home-assistant.overrideAttrs (old: {doInstallCheck = false;});
  in {
    inherit package;
    enable = true;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = ["cast" "default_config" "esphome" "met" "mqtt" "tasmota" "zha"];

    config = {
      default_config = {};

      homeassistant = {
        name = "Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
        time_zone = config.time.timeZone;
      };
      frontend = {};
      http = {
        ip_ban_enabled = true;
        login_attempts_threshold = 3;
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };
      zha.zigpy_config.ota.ikea_provider = true;

      "automation manual" = [];
      "automation ui" = "!include automations.yaml";
      "scene manual" = [];
      "scene ui" = "!include scenes.yaml";
    };

    customComponents = [
      (pkgs.my.hasl3.override {
        inherit (pkgs.unstable) buildHomeAssistantComponent;
        home-assistant = package;
      })
    ];

    customZhaQuirks = with pkgs.my.home-assistant-custom-zha-quirks; [
      tuya-persence-sensor-ts0225
    ];
  };

  # https://nixos.wiki/wiki/Home_Assistant#Combine_declarative_and_UI_defined_automations
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
  ];

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

  security.acme.certs = {${hassDomain} = {};};

  services.caddy.virtualHosts = {
    ${hassDomain} = {
      useACMEHost = hassDomain;
      extraConfig = ''
        reverse_proxy localhost:${toString hassPort}
      '';
    };
  };

  modules.impermanence.directories = [
    config.services.home-assistant.configDir
    config.services.mosquitto.dataDir
  ];
  modules.services.restic = {
    paths = [config.services.home-assistant.configDir];
    exclude = ["${config.services.home-assistant.configDir}/secrets.yaml"];
  };
}
