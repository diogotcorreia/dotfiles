# Configuration for Home Assistant (and related programs) on Feb
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant
{
  inputs,
  pkgs,
  config,
  secrets,
  ...
}: let
  hassDomain = "ha.feb.diogotc.com";
  hassPort = 8123;
in {
  age.secrets = {
    hassSecrets = {
      file = secrets.host.hassSecrets;
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
    extraComponents = ["default_config"];

    config = {
      default_config = {};

      homeassistant = {
        name = "Xperience House";
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

      "automation manual" = [];
      "automation ui" = "!include automations.yaml";
      "scene manual" = [];
      "scene ui" = "!include scenes.yaml";
    };

    customComponents = [
      (pkgs.my.hass-resol-km2.override {
        inherit (pkgs.unstable) buildHomeAssistantComponent;
      })
    ];
  };

  # https://nixos.wiki/wiki/Home_Assistant#Combine_declarative_and_UI_defined_automations
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
  ];

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
  ];
  modules.services.restic = {
    paths = [config.services.home-assistant.configDir];
    exclude = ["${config.services.home-assistant.configDir}/secrets.yaml"];
  };
}
