# Configuration for bacchus (laptop PC)
{
  config,
  lib,
  pkgs,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    graphical.captive-portals-client
    graphical.firefox
    graphical.firefox-proxied
    graphical.obs
    graphical.thunderbird
    hardware.bluetooth
    hardware.zram
    laptop.auto-timezone
    misc.cybersec
    misc.geoclue
    misc.kth
    networking.wireguard.ecsc
    services.ssh
    shell.gpg
    shell.zellij
    virtualisation.docker
    virtualisation.virtual-machines
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

  # /tmp configuration
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "80%";
  boot.tmp.cleanOnBoot = true;

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

  # Battery saver
  services.tlp.enable = true;

  # Don't shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';
  # Suspend even if plugged in to external monitor
  services.logind.lidSwitchDocked = "suspend";

  # Secret manager (agenix)
  age = {
    secrets = {
      bacchusNebulaCert = {
        file = secrets.host.nebulaCert;
        owner = "nebula-nebula0";
      };
      bacchusNebulaKey = {
        file = secrets.host.nebulaKey;
        owner = "nebula-nebula0";
      };
      bacchusResticHealthchecksUrl.file = secrets.host.resticHealthchecksUrl;
      bacchusResticRcloneConfig.file = secrets.host.resticRcloneConfig;
      bacchusResticPassword.file = secrets.host.resticPassword;
      bacchusResticSshKey.file = secrets.host.resticSshKey;
    };

    identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
  };

  # GnuPG (GPG)
  hm.programs.git.signing.key = "7B5273B10C4495CF";

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

  hardware.flipperzero.enable = true;

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
      wireguard-client = {
        # public key: HitADKIgPbbk2fhCxd9iuTsT683ayLithrwnQagb4B0=
        feb-router = {
          enable = true;
          lastOctect = 3;
        };
        hera = {
          enable = true;
          lastOctect = 3;
        };
      };
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    impermanence = {
      enable = true;
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
    personal.enable = true;
    secureboot.enable = true;
    xdg.enable = true;
  };

  # Wayland specialisation
  # TODO: make default
  specialisation.wayland.configuration = {
    imports = with profiles; [
      graphical.niri
    ];

    # Disable DWM configuration
    modules.graphical = {
      enable = lib.mkForce false;
      autorandr.laptop.enable = lib.mkForce false;
    };
  };

  # System state version
  system.stateVersion = "22.11";
}
