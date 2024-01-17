# hosts/bacchus/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for bacchus (PC).

{ pkgs, lib, sshKeys, config, hostSecretsDir, ... }: {
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;

  # ZFS
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.kernelParams = [ "nohibernate" ];
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
  services.automatic-timezoned.enable = true;
  systemd.services.automatic-timezoned.serviceConfig = {
    # zone1970.tab does not contain all timezones anymore, for some weird reason (e.g., Europe/Stockholm since 2022b)
    # Use deprecated zone.tab that includes all timezones
    ExecStart = lib.mkForce
      "${config.services.automatic-timezoned.package}/bin/automatic-timezoned --zoneinfo-path=${pkgs.tzdata}/share/zoneinfo/zone.tab";
  };

  # Network Manager
  # TODO move to module
  networking.networkmanager.enable = true;
  usr.extraGroups = [ "networkmanager" ];

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
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

  # Battery saver
  services.tlp.enable = true;

  # Don't shutdown when power button is short-pressed
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

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
      bacchusResticHealthchecksUrl.file =
        "${hostSecretsDir}/resticHealthchecksUrl.age";
      bacchusResticRcloneConfig.file =
        "${hostSecretsDir}/resticRcloneConfig.age";
      bacchusResticPassword.file = "${hostSecretsDir}/resticPassword.age";
      bacchusResticSshKey.file = "${hostSecretsDir}/resticSshKey.age";
    };

    identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
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
        firewall.inbound = [{
          port = 22;
          proto = "tcp";
          group = "dtc";
        }];
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
      files = [
        # Store automatic timezone between reboots
        "/etc/localtime"
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
