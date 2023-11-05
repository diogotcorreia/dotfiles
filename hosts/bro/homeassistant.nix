# hosts/bro/homeassistant.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Home Assistant (and related programs) on Bro
# Inspired by https://github.com/Mic92/dotfiles/tree/2580420b65b20196b72ab58d4541b2d972dec668/nixos/eve/modules/home-assistant

{ inputs, pkgs, config, hostSecretsDir, ... }:
let
  hassDomain = "ha.bro.diogotc.com";
  hassPort = 8123;
in {
  age.secrets = {
    hassSecrets = {
      file = "${hostSecretsDir}/hassSecrets.age";
      path =
        "/persist/${config.services.home-assistant.configDir}/secrets.yaml";
      mode = "400";
      owner = "hass";
      group = "hass";
    };
  };

  disabledModules = [ "services/home-automation/home-assistant.nix" ];
  imports = [
    (inputs.nixpkgs-unstable
      + "/nixos/modules/services/home-automation/home-assistant.nix")
  ];
  services.home-assistant = {
    enable = true;
    package = pkgs.unstable.home-assistant.overrideAttrs
      (old: { doInstallCheck = false; });

    config = {
      default_config = { };

      homeassistant = {
        name = "Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
        time_zone = config.time.timeZone;
      };
      frontend = { };
      http = {
        ip_ban_enabled = true;
        login_attempts_threshold = 3;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" "::1" ];
      };

      "automation manual" = [ ];
      "automation ui" = "!include automations.yaml";
      "scene manual" = [ ];
      "scene ui" = "!include scenes.yaml";
    };
  };

  # https://nixos.wiki/wiki/Home_Assistant#Combine_declarative_and_UI_defined_automations
  systemd.tmpfiles.rules = [
    "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
  ];

  networking.firewall.interfaces.br0 = {
    # UDP Port 5353 for mDNS discovery of Google Cast devices (Spotify)
    allowedUDPPorts = [ 5353 ];

    allowedTCPPorts = [ hassPort ];
  };

  security.acme.certs = { ${hassDomain} = { }; };

  services.caddy.virtualHosts = {
    ${hassDomain} = {
      useACMEHost = hassDomain;
      extraConfig = ''
        reverse_proxy localhost:${toString hassPort}
      '';
    };
  };

  modules.impermanence.directories =
    [ config.services.home-assistant.configDir ];
  modules.services.restic = {
    paths = [ config.services.home-assistant.configDir ];
    exclude = [ "${config.services.home-assistant.configDir}/secrets.yaml" ];
  };
}