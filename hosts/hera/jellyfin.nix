# Configuration for Jellyfin on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  domainJellyfin = "jellyfin.diogotc.com";
  portJellyfin = lib.my.ports.jellyfin;
  domainRadarr = "radarr.hera.diogotc.com";
  portRadarr = lib.my.ports.radarr;
  domainSonarr = "sonarr.hera.diogotc.com";
  portSonarr = lib.my.ports.sonarr;
  domainJackett = "jackett.hera.diogotc.com";
  portJackett = lib.my.ports.jackett;
  domainBazarr = "bazarr.hera.diogotc.com";
  portBazarr = lib.my.ports.bazarr;

  bazarrDirectory = "/var/lib/bazarr";

  diskstationAddress = "192.168.1.4";
  mediaGroup = "diskstation-media";

  transmissionGroup = config.services.transmission.group;
in {
  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  nixpkgs.overlays = [
    (final: prev: {
      intel-vaapi-driver =
        prev.intel-vaapi-driver.override {enableHybridCodec = true;};
    })
  ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  services.jellyfin.enable = true;
  services.radarr = {
    enable = true;
    package = pkgs.unstable.radarr;
  };
  services.sonarr = {
    enable = true;
    package = pkgs.unstable.sonarr;
  };
  services.jackett = {
    enable = true;
    package = pkgs.unstable.jackett;
  };
  services.bazarr = {
    enable = true;
    listenPort = portBazarr;
  };

  age.secrets.diskstationSambaCredentials.file = secrets.host.diskstationSambaCredentials;

  # NAS mounts
  fileSystems."/media/diskstation" = {
    device = "//${diskstationAddress}/video";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

      permissions = "uid=root,gid=${mediaGroup},file_mode=0664,dir_mode=0775";
    in [
      "${automount_opts},vers=2.0,credentials=${config.age.secrets.diskstationSambaCredentials.path},nobrl,${permissions}"
    ];
  };

  # Open Jellyfin local discovery ports
  # https://jellyfin.org/docs/general/networking/index.html
  networking.firewall.allowedUDPPorts = with lib.my.ports; [
    jellyfinAutoDiscoveryDlna
    jellyfinAutoDiscoveryClients
  ];

  services.caddy.virtualHosts = {
    ${domainJellyfin} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString portJellyfin}
      '';
    };
    ${domainRadarr} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString portRadarr}
      '';
    };
    ${domainSonarr} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString portSonarr}
      '';
    };
    ${domainJackett} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString portJackett}
      '';
    };
    ${domainBazarr} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString portBazarr}
      '';
    };
  };

  my.services.authelia.accessRules = [
    {
      domain = [domainBazarr domainRadarr domainSonarr domainJackett];
      subject = "group:arrs";
    }
  ];

  users.groups.${mediaGroup} = {};
  users.users = {
    ${config.services.radarr.user}.extraGroups = [mediaGroup transmissionGroup];
    ${config.services.sonarr.user}.extraGroups = [mediaGroup transmissionGroup];
    ${config.services.bazarr.user}.extraGroups = [mediaGroup];
  };

  modules.impermanence.directories = [
    "/var/lib/jellyfin"
    # also persist cache so we don't have to fetch metadata on every reboot
    "/var/cache/jellyfin"

    config.services.radarr.dataDir
    config.services.sonarr.dataDir
    config.services.jackett.dataDir
    bazarrDirectory
  ];

  modules.services.restic.paths = [
    "/var/lib/jellyfin"
    config.services.radarr.dataDir
    config.services.sonarr.dataDir
    config.services.jackett.dataDir
    bazarrDirectory
  ];
}
