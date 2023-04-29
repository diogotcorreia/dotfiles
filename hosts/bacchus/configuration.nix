# hosts/bacchus/configuration.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for bacchus (PC).

{ pkgs, lib, sshKeys, config, hostSecretsDir, user, agenixPackage, ... }: {
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
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "80%";
  boot.cleanTmpDir = true;

  # Impermanence (root on tmpfs)
  environment.persistence."/persist" = {
    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/docker"
      "/var/lib/libvirt"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  # Network Manager
  # TODO move to module
  networking.networkmanager.enable = true;
  usr.extraGroups = [ "networkmanager" ];

  # SSH server
  # TODO move to module
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    kbdInteractiveAuthentication = false;
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
      bacchusNebulaCert.file = "${hostSecretsDir}/nebulaCert.age";
      bacchusNebulaKey.file = "${hostSecretsDir}/nebulaKey.age";
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
      programs.enable = true;
      qt.enable = true;
    };
    services = {
      dnsovertls.enable = true;
      # Nebula (VPN)
      nebula = {
        enable = true;
        cert = config.age.secrets.bacchusNebulaCert.path;
        key = config.age.secrets.bacchusNebulaKey.path;
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
    ist.enable = true;
    personal.enable = true;
    xdg.enable = true;
  };

  # Statem state version
  system.stateVersion = "22.11";
}
