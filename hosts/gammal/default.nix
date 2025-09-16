# Configuration for gammal (third-party laptop)
{
  config,
  lib,
  pkgs,
  profiles,
  secrets,
  user,
  ...
}:
{
  imports = with profiles; [
    graphical.cinnamon
    hardware.filesystem.ext4-impermanence
    hardware.zram
    laptop.auto-timezone
    meta.common
  ];

  networking.hostId = "b884eaac";
  my.filesystem.mainDisk = "/dev/sda";
  my.filesystem.espSize = "128M";
  my.filesystem.useEfi = false; # laptop does not support UEFI

  # /tmp configuration
  boot.tmp.cleanOnBoot = true;

  my.networking.wiredInterface = "enp2s0";
  my.networking.wirelessInterface = "wlp3s0";

  age.secrets.titaHashedPassword.file = secrets.host.titaHashedPassword;

  users.users.tita = {
    isNormalUser = true;
    createHome = true;
    hashedPasswordFile = config.age.secrets.titaHashedPassword.path;
  };

  # Specific packages for this host
  environment.systemPackages = with pkgs; [
    # Browser
    firefox
    # Office Suite
    libreoffice
    # Music
    spotify
    # Video Conferencing
    zoom-us
  ];

  # Modules
  modules = {
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
    };
    # TODO: get rid of this
    shell.zsh.enable = true;
  };

  my.autoUpgrade = {
    enable = true;
    operation = "switch";

    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
    allowReboot = true;
    flags = [
      # Prevent building on local machine (always fetch from cache)
      "--max-jobs"
      "0"
      "--cores"
      "1"
    ];

    dates = "04:00";
    randomizedDelaySec = "1h";
  };
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    options = "-d"; # delete old generations

    dates = "weekly";
    randomizedDelaySec = "2h";
  };
  hm.nix.gc = {
    automatic = true;
    options = "-d"; # delete old generations

    frequency = "weekly";
  };

  # Hide "dtc" user from display manager
  services.displayManager.hiddenUsers = [ user ];

  modules.impermanence.directories = [ "/home" ];
  # https://github.com/nix-community/impermanence/issues/276
  fileSystems."/home".neededForBoot = true;

  # System state version
  system.stateVersion = "25.05";
}
