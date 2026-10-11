{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  # deadnix: skip
  utils, # needs to be here for the import of unstable music-assistant
  ...
}@args:
let
  inherit (lib)
    mkIf
    mkOption
    types
    ;

  cfg = config.services.music-assistant;

  dataDir = "/var/lib/music-assistant";
in
{
  # Extend home-assistant module with extra options
  options.services.music-assistant = {
    useSensibleDefaults = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to use sensible defaults, such as:

        - Configure impermanence
        - Configure backups
      '';
    };
    externalDomain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The external domain of this Home Assistant instance.
        If not null, Nginx is configured automatically.
      '';
    };
  };

  # Use module from nixos-unstable
  disabledModules = [
    "services/audio/music-assistant.nix"
  ];
  imports = [
    (import (inputs.nixpkgs-unstable + "/nixos/modules/services/audio/music-assistant.nix") (
      args // { pkgs = pkgs.unstable; }
    ))
  ];

  config = mkIf cfg.enable {
    # https://github.com/music-assistant/server/blob/5456607e50f70fe7b5d9446d6909121c8487f952/music_assistant/helpers/app_vars.py#L13
    age.secrets.musicAssistantAppSecrets.file = secrets.musicAssistantAppSecrets;

    services.music-assistant = {
      # Use package from nixos-unstable
      package = pkgs.unstable.music-assistant;
      extraOptions = [
        "--config"
        dataDir
      ];
    };

    systemd.services.music-assistant = {
      serviceConfig = {
        LoadCredential = [
          "app-secrets:${config.age.secrets.musicAssistantAppSecrets.path}"
        ];
      };
      environment = {
        MASS_APP_VARS_FILE = "%d/app-secrets";
      };
    };

    modules.impermanence.directories = mkIf cfg.useSensibleDefaults [
      (lib.my.toPrivateStateDirectory dataDir)
    ];
    modules.services.restic = mkIf cfg.useSensibleDefaults {
      paths = [
        (lib.my.toPrivateStateDirectory dataDir)
      ];
    };

    # Configure Nginx
    services.nginx.virtualHosts = mkIf (cfg.externalDomain != null) {
      ${cfg.externalDomain} = {
        enableACME = true;
        locations."/".proxyPass = "http://[::1]:${toString lib.my.ports.musicAssistantWeb}";
      };
    };
  };
}
