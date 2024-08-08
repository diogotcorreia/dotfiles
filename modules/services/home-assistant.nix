{
  config,
  inputs,
  lib,
  pkgs,
  secrets,
  ...
}: let
  inherit
    (lib)
    escapeShellArg
    escapeShellArgs
    mdDoc
    mkAfter
    mkDefault
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.services.home-assistant;

  quirksDir = "${cfg.configDir}/zha-quirks";
in {
  # Extend home-assistant module with extra options
  options.services.home-assistant = {
    useSensibleDefaults = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc ''
        Whether to use sensible defaults, such as:

        - Load `secrets.yaml` from agenix
        - Set `default_config`, `name`, `latitude`, `longitude`,
          `elevation`, `unit_system`, `time_zone`, `frontend`,
          `http.*` on config.yml.
        - Enable support for combined declarative and UI automations/scenes.
        - Configure impermanence
        - Configure backups
      '';
    };
    externalDomain = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc ''
        The external domain of this Home Assistant instance.
        If not null, Caddy is configured automatically.
      '';
    };
    customZhaQuirks = mkOption {
      type = types.listOf types.path;
      default = [];
      description = mdDoc ''
        List of custom ZHA (Zigbee) quirks to load.

        Available quirks can be found below `pkgs.my.home-assistant-custom-zha-quirks`.
      '';
    };
  };

  # Use module from nixos-unstable
  disabledModules = [
    "services/home-automation/home-assistant.nix"
  ];
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/home-automation/home-assistant.nix")
  ];

  config = mkIf cfg.enable {
    systemd.services.home-assistant.preStart = let
      copyZhaQuirks = ''
        mkdir -p ${escapeShellArg quirksDir}

        # remove quirks symlinked in from below the /nix/store
        readarray -d "" quirks < <(find ${escapeShellArg quirksDir} -maxdepth 1 -type l -print0)
        for quirk in "''${quirks[@]}"; do
          if [[ "$(readlink "$quirk")" =~ ^${escapeShellArg builtins.storeDir} ]]; then
            rm "$quirk"
          fi
        done

        # recreate symlinks for desired quirks
        declare -a quirks=(${escapeShellArgs cfg.customZhaQuirks})
        for quirk in "''${quirks[@]}"; do
          ln -fs "$quirk" ${escapeShellArg quirksDir}
        done
      '';
    in
      mkAfter copyZhaQuirks;

    age.secrets = mkIf cfg.useSensibleDefaults {
      hassSecrets = {
        file = secrets.host.hassSecrets;
        path = "/persist/${config.services.home-assistant.configDir}/secrets.yaml";
        mode = "400";
        owner = "hass";
        group = "hass";
      };
    };

    services.home-assistant = {
      # Use package from nixos-unstable
      package = pkgs.unstable.home-assistant.overrideAttrs (old: {doInstallCheck = false;});

      config =
        {
          zha = mkIf (cfg.customZhaQuirks != []) {
            enable_quirks = true;
            custom_quirks_path = quirksDir;
          };
        }
        // (optionalAttrs cfg.useSensibleDefaults {
          default_config = {};
          frontend = {};

          homeassistant = {
            name = mkDefault "Home";
            latitude = mkDefault "!secret latitude";
            longitude = mkDefault "!secret longitude";
            elevation = mkDefault "!secret elevation";
            unit_system = mkDefault "metric";
            time_zone = mkDefault config.time.timeZone;
          };

          http = {
            ip_ban_enabled = mkDefault true;
            login_attempts_threshold = mkDefault 3;
            use_x_forwarded_for = mkDefault true;
            trusted_proxies = mkDefault ["127.0.0.1" "::1"];
          };

          "automation manual" = [];
          "automation ui" = "!include automations.yaml";
          "scene manual" = [];
          "scene ui" = "!include scenes.yaml";
        });
    };

    # https://nixos.wiki/wiki/Home_Assistant#Combine_declarative_and_UI_defined_automations
    systemd.tmpfiles.rules = mkIf cfg.useSensibleDefaults [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
      "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
    ];

    modules.impermanence.directories = mkIf cfg.useSensibleDefaults [
      config.services.home-assistant.configDir
    ];
    modules.services.restic = mkIf cfg.useSensibleDefaults {
      paths = [config.services.home-assistant.configDir];
      exclude = ["${config.services.home-assistant.configDir}/secrets.yaml"];
    };

    # Configure Caddy
    security.acme.certs = mkIf (cfg.externalDomain != null) {
      ${cfg.externalDomain} = {};
    };
    services.caddy.virtualHosts = mkIf (cfg.externalDomain != null) {
      ${cfg.externalDomain} = {
        useACMEHost = cfg.externalDomain;
        extraConfig = ''
          reverse_proxy localhost:${toString cfg.config.http.server_port}
        '';
      };
    };
  };
}
