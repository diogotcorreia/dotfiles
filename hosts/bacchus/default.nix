# Configuration for bacchus (laptop PC)
{
  config,
  configDir,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    editors.neovim.personal
    graphical.caido
    graphical.captive-portals-client
    graphical.discord
    graphical.firefox
    graphical.firefox-proxied
    graphical.niri
    graphical.obs
    graphical.spotify
    graphical.thunderbird
    hardware.bluetooth
    hardware.zram
    laptop.auto-timezone
    meta.personal
    misc.cybersec
    misc.geoclue
    misc.kth
    networking.wireguard.ctf
    security.secureboot
    services.frp.client
    shell.gpg
    shell.nix-index
    shell.zellij
    virtualisation.podman
    virtualisation.virtual-machines
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelParams = [ "nohibernate" ];
  boot.zfs.forceImportRoot = false; # TODO 26.11: remove after changing stateVersion
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
  usr.extraGroups = [ "networkmanager" ];
  environment.etc."certs/ist.crt".source = "${configDir}/certs/ist.crt";
  environment.etc."certs/kth.crt".source = "${configDir}/certs/kth.crt";

  my.networking.wirelessInterface = "wlo1";
  my.hardware.laptop = true;

  my.graphical.monitorDirection = "vertically";
  my.graphical.monitors = [
    {
      name = "HDMI-A-1";
      position = {
        x = 0;
        y = 0;
      };
    }
    {
      name = "eDP-1";
      primary = true;
      position = {
        x = 0;
        y = 1200;
      };
    }
  ];

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

  services.logind.settings.Login = {
    # Don't shutdown when power button is short-pressed
    HandlePowerKey = "ignore";
    # Suspend even if plugged in to external monitor
    HandleLidSwitchDocked = "suspend";
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
    libreoffice-fresh
    # Minecraft Launcher
    prismlauncher
    # Steam Run
    # TODO Move to modules
    steam-run
    # Karaoke Game
    ultrastardx
    # Reference Manager
    zotero
  ];

  hardware.flipperzero.enable = true;

  # Modules
  modules = {
    graphical = {
      development.enable = true;
      gtk.enable = true;
      programs.enable = true;
      qt.enable = true;
      wacom = {
        enable = true;
        monitor = "eDP-1";
      };
      xournalpp.enable = true;
    };
    services = {
      dnsoverhttps.enable = true;
      # Nebula (VPN)
      nebula.enable = true;
      restic = {
        enable = true;

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
        bro = {
          enable = true;
          lastOctect = 3;
        };
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
    };
    impermanence = {
      enable = true;
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
    personal.enable = true;
    xdg.enable = true;
  };

  # System state version
  system.stateVersion = "25.11";
}
