# hosts/apollo/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for apollo (PC).
{
  pkgs,
  lib,
  sshKeys,
  config,
  hostSecretsDir,
  ...
}: {
  # ZFS configuration
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

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
    interfaces.enp9s0 = {
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
      interface = "enp9s0";
    };
  };

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  usr.openssh.authorizedKeys.keys = sshKeys;

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

  # Don't shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  # Docker (containers)
  virtualisation.docker.enable = true;

  # Secret manager (agenix)
  age = {
    secrets = {
      apolloNebulaCert = {
        file = "${hostSecretsDir}/nebulaCert.age";
        owner = "nebula-nebula0";
      };
      apolloNebulaKey = {
        file = "${hostSecretsDir}/nebulaKey.age";
        owner = "nebula-nebula0";
      };
      apolloResticHealthchecksUrl.file = "${hostSecretsDir}/resticHealthchecksUrl.age";
      apolloResticRcloneConfig.file = "${hostSecretsDir}/resticRcloneConfig.age";
      apolloResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      apolloResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
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
        cert = config.age.secrets.apolloNebulaCert.path;
        key = config.age.secrets.apolloNebulaKey.path;
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
        checkUrlFile = config.age.secrets.apolloResticHealthchecksUrl.path;
        rcloneConfigFile = config.age.secrets.apolloResticRcloneConfig.path;
        passwordFile = config.age.secrets.apolloResticPassword.path;
        sshKeyFile = config.age.secrets.apolloResticSshKey.path;

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
      ];
    };
    ist.enable = true;
    kth.enable = true;
    personal.enable = true;
    secureboot.enable = true;
    xdg.enable = true;
  };

  # Statem state version
  system.stateVersion = "23.11";
}
