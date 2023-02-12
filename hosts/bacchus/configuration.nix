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

  # Nvidia
  # TODO move to module
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.nvidia.prime = {
    offload.enable = true;

    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:2:0:0";
  };
  hardware.nvidia.forceFullCompositionPipeline = true;
  environment.systemPackages = let
    nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '';
  in ([ nvidia-offload ]);

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
  hm.home.packages = with pkgs;
    [
      # Arrange external displays
      arandr
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
