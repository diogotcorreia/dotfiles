# Heavily inspired from https://github.com/NixOS/nixpkgs/blob/2b4230bf03deb33103947e2528cac2ed516c5c89/nixos/modules/tasks/auto-upgrade.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.autoUpgrade;
in
{
  options = {
    my.autoUpgrade = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to periodically upgrade NixOS to the latest
          version. If enabled, a systemd timer will run
          `nixos-rebuild switch --upgrade` once a
          day.
        '';
      };

      operation = lib.mkOption {
        type = lib.types.enum [
          "switch"
          "boot"
        ];
        default = "switch";
        example = "boot";
        description = ''
          Whether to run
          `nixos-rebuild switch --upgrade` or run
          `nixos-rebuild boot --upgrade`
        '';
      };

      storePathUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "https://infra-keyval.diogotc.com/nixos-system-${config.networking.hostName}";
        description = ''
          The URL to fetch to get the store path of the NixOS configuration
          switch to.
        '';
      };

      flags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "-I"
          "stuff=/home/alice/nixos-stuff"
          "--option"
          "extra-binary-caches"
          "http://my-cache.example.org/"
        ];
        description = ''
          Any additional flags passed to {command}`nix`.
        '';
      };

      dates = lib.mkOption {
        type = lib.types.str;
        default = "04:40";
        example = "daily";
        description = ''
          How often or when upgrade occurs. For most desktop and server systems
          a sufficient upgrade frequency is once a day.

          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };

      allowReboot = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Reboot the system into the new generation instead of a switch
          if the new generation uses a different kernel, kernel modules
          or initrd than the booted system.
          See {option}`rebootWindow` for configuring the times at which a reboot is allowed.
        '';
      };

      randomizedDelaySec = lib.mkOption {
        default = "0";
        type = lib.types.str;
        example = "45min";
        description = ''
          Add a randomized delay before each automatic upgrade.
          The delay will be chosen between zero and this value.
          This value must be a time span in the format specified by
          {manpage}`systemd.time(7)`
        '';
      };

      fixedRandomDelay = lib.mkOption {
        default = false;
        type = lib.types.bool;
        example = true;
        description = ''
          Make the randomized delay consistent between runs.
          This reduces the jitter between automatic upgrades.
          See {option}`randomizedDelaySec` for configuring the randomized delay.
        '';
      };

      rebootWindow = lib.mkOption {
        description = ''
          Define a lower and upper time value (in HH:MM format) which
          constitute a time window during which reboots are allowed after an upgrade.
          This option only has an effect when {option}`allowReboot` is enabled.
          The default value of `null` means that reboots are allowed at any time.
        '';
        default = null;
        example = {
          lower = "01:00";
          upper = "05:00";
        };
        type =
          with lib.types;
          nullOr (submodule {
            options = {
              lower = lib.mkOption {
                description = "Lower limit of the reboot window";
                type = lib.types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
                example = "01:00";
              };

              upper = lib.mkOption {
                description = "Upper limit of the reboot window";
                type = lib.types.strMatching "[[:digit:]]{2}:[[:digit:]]{2}";
                example = "05:00";
              };
            };
          });
      };

      persistent = lib.mkOption {
        default = true;
        type = lib.types.bool;
        example = false;
        description = ''
          Takes a boolean argument. If true, the time when the service
          unit was last triggered is stored on disk. When the timer is
          activated, the service unit is triggered immediately if it
          would have been triggered at least once during the time when
          the timer was inactive. Such triggering is nonetheless
          subject to the delay imposed by RandomizedDelaySec=. This is
          useful to catch up on missed runs of the service when the
          system was powered down.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.system.autoUpgrade.enable;
        message = ''
          The options 'system.autoUpgrade.enable' and 'my.autoUpgrade.enable' cannot both be set.
        '';
      }
    ];

    my.autoUpgrade.flags = [
      "--refresh"
      "--no-link"
    ];

    systemd.services.nixos-upgrade = {
      description = "NixOS Upgrade";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";

      environment =
        config.nix.envVars
        // {
          inherit (config.environment.sessionVariables) NIX_PATH;
          HOME = "/root";
        }
        // config.networking.proxy.envVars;

      path = with pkgs; [
        coreutils
        gnutar
        xz.bin
        gzip
        gitMinimal
        config.nix.package.out
        config.programs.ssh.package
      ];

      script =
        let
          curl = "${pkgs.curl}/bin/curl";
          date = "${pkgs.coreutils}/bin/date";
          readlink = "${pkgs.coreutils}/bin/readlink";
          shutdown = "${config.systemd.package}/bin/shutdown";

          fetchFromCache = ''
            nix build ${lib.escapeShellArgs cfg.flags} -- "$config_store_path"
          '';
          setProfile = ''
            nix-env -p /nix/var/nix/profiles/system --set "$config_store_path"
          '';
          switchToConfiguration = action: ''
            systemd-run \
              -E LOCALE_ARCHIVE \
              -E NIXOS_INSTALL_BOOTLOADER= \
              --collect \
              --no-ask-password \
              --pipe \
              --quiet \
              --service-type=exec \
              --unit=nixos-rebuild-switch-to-configuration \
              --wait \
              "$config_store_path/bin/switch-to-configuration" \
              ${lib.escapeShellArg action}
          '';
        in
        if cfg.allowReboot then
          ''
            config_store_path="$(${curl} --url ${lib.escapeShellArg cfg.storePathUrl})"
            if [[ ! "$config_store_path" =~ ^\/nix\/store\/[a-z0-9]{32}-nixos-system-${config.networking.hostName}-[0-9]{2}\.[0-9]{2}\.[0-9]{8}\.[a-z0-9]{7,}$ ]]; then
              echo "fetched store path does not match expected format: $config_store_path"
              exit 1
            fi

            ${fetchFromCache}
            ${setProfile}
            ${switchToConfiguration "boot"}

            booted="$(${readlink} /run/booted-system/{initrd,kernel,kernel-modules})"
            built="$(${readlink} /nix/var/nix/profiles/system/{initrd,kernel,kernel-modules})"

            ${lib.optionalString (cfg.rebootWindow != null) ''
              current_time="$(${date} +%H:%M)"

              lower="${cfg.rebootWindow.lower}"
              upper="${cfg.rebootWindow.upper}"

              if [[ "''${lower}" < "''${upper}" ]]; then
                if [[ "''${current_time}" > "''${lower}" ]] && \
                   [[ "''${current_time}" < "''${upper}" ]]; then
                  do_reboot="true"
                else
                  do_reboot="false"
                fi
              else
                # lower > upper, so we are crossing midnight (e.g. lower=23h, upper=6h)
                # we want to reboot if cur > 23h or cur < 6h
                if [[ "''${current_time}" < "''${upper}" ]] || \
                   [[ "''${current_time}" > "''${lower}" ]]; then
                  do_reboot="true"
                else
                  do_reboot="false"
                fi
              fi
            ''}

            if [ "''${booted}" = "''${built}" ]; then
              ${switchToConfiguration cfg.operation}
            ${lib.optionalString (cfg.rebootWindow != null) ''
              elif [ "''${do_reboot}" != true ]; then
                echo "Outside of configured reboot window, skipping."
            ''}
            else
              ${shutdown} -r +1
            fi
          ''
        else
          ''
            ${fetchFromCache}
            ${setProfile}
            ${switchToConfiguration cfg.operation}
          '';

      startAt = cfg.dates;

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.timers.nixos-upgrade = {
      timerConfig = {
        RandomizedDelaySec = cfg.randomizedDelaySec;
        FixedRandomDelay = cfg.fixedRandomDelay;
        Persistent = cfg.persistent;
      };
    };
  };
}
