# Configuration for apollo (desktop PC)
{
  config,
  lib,
  pkgs,
  profiles,
  ...
}:
{
  imports = with profiles; [
    graphical.caido
    graphical.discord
    graphical.firefox
    graphical.firefox-proxied
    graphical.spotify
    graphical.thunderbird
    hardware.bluetooth
    hardware.filesystem.zfs-impermanence
    hardware.zram
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
    virtualisation.docker
    virtualisation.virtual-machines
  ];

  networking.hostId = "30c1f688";

  my.filesystem.mainDisk = "/dev/nvme0n1";

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  # Time zone
  time.timeZone = "Europe/Lisbon";

  # Order monitors
  services.xserver.displayManager.setupCommands = ''
    ${pkgs.xlibs.xrandr}/bin/xrandr \
       --dpi 96 \
       --output HDMI-0 --mode 1280x1024 --rate 75 --pos 0x0 \
       --output DVI-D-0 --mode 1920x1080 --rate 60 --pos 1280x0 --primary \
       --output DP-0 --mode 1920x1080 --rate 60 --pos 3200x0
  '';

  # Network Manager
  networking = {
    interfaces.${config.my.networking.wiredInterface} = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.1.2";
            prefixLength = 24;
          }
        ];
      };
      wakeOnLan.enable = true;
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = config.my.networking.wiredInterface;
    };
  };

  my.networking.wiredInterface = "enp9s0";

  my.graphical.monitorDirection = "horizontally";
  my.graphical.monitors = [
    {
      name = "HDMI-A-1";
      position = {
        x = 0;
        y = 0;
      };
    }
    {
      name = "DVI-D-1";
      primary = true;
      position = {
        x = 1280;
        y = 0;
      };
    }
    {
      name = "DP-1";
      position = {
        x = 3200;
        y = 0;
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

  # Don't shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  # Disable Docker on boot
  virtualisation.docker.enableOnBoot = false;

  # GnuPG (GPG)
  hm.programs.git.signing.key = "12B4F3AC9C065D08";

  # Specific packages for this host
  hm.home.packages = with pkgs; [
    # Arrange external displays
    arandr
    # Git LFS pure SSH server implementation
    git-lfs-transfer
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
  ];

  # Modules
  modules = {
    editors.neovim.enable = true;
    graphical = {
      enable = true;
      development.enable = true;
      gtk.enable = true;
      programs.enable = true;
      qt.enable = true;
      wacom = {
        enable = true;
        monitor = "HEAD-0"; # nvidia drivers don't work with DVI-D-0
      };
      xournalpp.enable = true;
    };
    services = {
      dnsoverhttps.enable = true;
      # Nebula (VPN)
      nebula = {
        enable = true;
        firewall.inbound = [
          {
            port = lib.my.ports.ssh;
            proto = "tcp";
            group = "dtc";
          }
        ];
      };
      restic = {
        enable = true;

        paths = [
          "${config.my.homeDirectory}/.ultrastardx"
          "${config.my.homeDirectory}/documents"
          "${config.my.homeDirectory}/pictures"
          "/media/files/documents"
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
    };
    shell = {
      git.enable = true;
      lf.enable = true;
      zsh.enable = true;
    };
    impermanence = {
      directories = [
        "/etc/NetworkManager/system-connections"
      ];
    };
    personal.enable = true;
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
  system.stateVersion = "23.11";
}
