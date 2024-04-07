# Configuration for bacchus (laptop PC)
{
  config,
  hostSecretsDir,
  lib,
  pkgs,
  profiles,
  ...
}: {
  imports = with profiles; [
    services.ssh
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  # ZFS
  boot.supportedFilesystems = ["zfs"];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.kernelParams = ["nohibernate"];
  networking.hostId = "239be557";
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  zramSwap.enable = true;

  # /tmp configuration
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "80%";
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = null;
  services.automatic-timezoned = {
    enable = true;
    package = pkgs.unstable.automatic-timezoned;
  };
  systemd.services.automatic-timezoned = {
    serviceConfig = {
      # TODO remove on nixos-24.05
      ExecStart = lib.mkForce "${lib.getExe config.services.automatic-timezoned.package}";

      StateDirectory = "automatic-timezoned";
      StateDirectoryMode = "0755";
    };

    # Restore timezone from previous boot
    preStart = ''
      if [[ -f "$STATE_DIRECTORY/timezone" ]]; then
        timezone=$(cat "$STATE_DIRECTORY/timezone")
        if [[ -n "$timezone" ]]; then
          ${lib.getExe' pkgs.dbus "dbus-send"} --system \
            --dest=org.freedesktop.timedate1 \
            --print-reply /org/freedesktop/timedate1 \
            org.freedesktop.timedate1.SetTimezone \
            string:"$timezone" \
            boolean:false
        fi
      fi
    '';
    postStop = ''
      if [[ "$SERVICE_RESULT" == "success" && -h /etc/localtime ]]; then
        # Can't use D-Bus here because it doesn't work on shutdown
        timezone=$(readlink /etc/localtime | sed 's/\.\.\/etc\/zoneinfo\///')
        if [[ -n "$timezone" ]]; then
          echo "$timezone" > "$STATE_DIRECTORY/timezone"
        fi
      fi
    '';
  };

  # Network Manager
  # TODO move to module
  networking.networkmanager = {
    enable = true;
    ethernet.macAddress = "stable";
    wifi.macAddress = "stable";
  };
  usr.extraGroups = ["networkmanager"];

  my.networking.wirelessInterface = "wlo1";

  # Audio
  # TODO move to module
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Battery saver
  services.tlp.enable = true;

  # Don't shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';
  # Suspend even if plugged in to external monitor
  services.logind.lidSwitchDocked = "suspend";

  # Docker (containers)
  virtualisation.docker.enable = true;

  # Secret manager (agenix)
  age = {
    secrets = {
      bacchusNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      bacchusNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      bacchusResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      bacchusResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      bacchusResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      bacchusResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # GnuPG (GPG)
  hm.programs.gpg.enable = true;
  hm.services.gpg-agent.enable = true;
  hm.programs.git.signing = {
    key = "7B5273B10C4495CF";
    signByDefault = true;
  };

  # Specific packages for this host
  hm.home.packages = with pkgs; [
    # Arrange external displays
    arandr
    # Heroic Games Launcher (FOSS Epic Games Launcher)
    heroic
    # Office Suite
    libreoffice
    # Minecraft Launcher
    prismlauncher
    # Steam Run
    # TODO Move to modules
    steam-run
    # Karaoke Game
    ultrastardx
  ];

  # Modules
  modules = {
    editors.neovim.enable = true;
    graphical = {
      enable = true;
      autorandr.laptop.enable = true;
      development.enable = true;
      gtk.enable = true;
      programs = {
        enable = true;
        laptop = true;
      };
      qt.enable = true;
      wacom = {
        enable = true;
        monitor = "eDP1";
      };
      xournalpp.enable = true;
    };
    services = {
      dnsoverhttps.enable = true;
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.bacchusNebulaCert.path;
        key = config.age.secrets.bacchusNebulaKey.path;
        firewall.inbound = [
          {
            port = 22;
            proto = "tcp";
            group = "dtc";
          }
        ];
      };
      restic = {
        enable = true;
        checkUrlFile = config.age.secrets.bacchusResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.bacchusResticRcloneConfig.path;
        passwordFile = config.age.secrets.bacchusResticPassword.path;
        sshKeyFile = config.age.secrets.bacchusResticSshKey.path;

        paths = [
          "${config.my.homeDirectory}/.ultrastardx"
          "${config.my.homeDirectory}/documents"
          "${config.my.homeDirectory}/games/Heroic/Prefixes/default/Overcooked 2/pfx/drive_c/users/steamuser/AppData/LocalLow/Team17/Overcooked2"
          "${config.my.homeDirectory}/pictures"
        ];
        exclude = [
          "${config.my.homeDirectory}/.ultrastardx/logs"
          "${config.my.homeDirectory}/.ultrastardx/songs"
          "${config.my.homeDirectory}/documents/vcs"
          ".git"
        ];

        timerConfig = {
          OnCalendar = "07:00";
          Persistent = true;
        };
      };
      syncthing.enable = true;
      wireguard-client.hera = {
        # public key: HitADKIgPbbk2fhCxd9iuTsT683ayLithrwnQagb4B0=
        enable = true;
        lastOctect = 3;
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    cybersec.enable = true;
    impermanence = {
      enable = true;
      # Impermanence (root on tmpfs)
      directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/docker"

        "/var/lib/automatic-timezoned"
      ];
    };
    ist.enable = true;
    kth.enable = true;
    personal.enable = true;
    secureboot.enable = true;
    virtual-machines.enable = true;
    xdg.enable = true;
  };

  # Statem state version
  system.stateVersion = "22.11";
}
