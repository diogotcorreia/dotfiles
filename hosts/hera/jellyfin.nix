# Configuration for Jellyfin on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domainJellyfin = "jellyfin.diogotc.com";
  portJellyfin = lib.my.ports.jellyfin;
  domainJellyseerr = "jellyseerr.diogotc.com";
  domainSeerr = "seerr.diogotc.com";
  portSeerr = lib.my.ports.seerr;
  domainRadarr = "radarr.hera.diogotc.com";
  portRadarr = lib.my.ports.radarr;
  domainSonarr = "sonarr.hera.diogotc.com";
  portSonarr = lib.my.ports.sonarr;
  domainJackett = "jackett.hera.diogotc.com";
  portJackett = lib.my.ports.jackett;
  domainBazarr = "bazarr.hera.diogotc.com";
  portBazarr = lib.my.ports.bazarr;

  seerrDb = "seerr";
  radarrMainDb = "radarr-main";
  radarrLogDb = "radarr-log";
  sonarrMainDb = "sonarr-main";
  sonarrLogDb = "sonarr-log";

  bazarrDirectory = "/var/lib/bazarr";

  diskstationAddress = "192.168.1.4";
  mediaGroup = "diskstation-media";

  transmissionGroup = config.services.transmission.group;
in
{
  # https://nixos.wiki/wiki/Accelerated_Video_Playback
  nixpkgs.overlays = [
    (_final: prev: {
      intel-vaapi-driver = prev.intel-vaapi-driver.override { enableHybridCodec = true; };
    })
  ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  services.jellyfin.enable = true;
  services.seerr = {
    enable = true;
    port = portSeerr;
    configDir = "/var/lib/seerr/"; # TODO: remove when stateVersion is bumped to 26.05
  };
  services.radarr = {
    enable = true;
    settings = {
      server = {
        port = portRadarr;
        bindAddress = "[::1]";
      };
      auth = {
        required = "Enabled";
        method = "External"; # via authelia header
      };
      postgres = {
        host = "/run/postgresql";
        user = "radarr";
        maindb = radarrMainDb;
        logdb = radarrLogDb;
      };
    };
  };
  services.sonarr = {
    enable = true;
    settings = {
      server = {
        port = portSonarr;
        bindAddress = "[::1]";
      };
      auth = {
        required = "Enabled";
        method = "External"; # via authelia header
      };
      postgres = {
        host = "/run/postgresql";
        user = "sonarr";
        maindb = sonarrMainDb;
        logdb = sonarrLogDb;
      };
    };
  };
  services.jackett = {
    enable = true;
  };
  services.bazarr = {
    enable = true;
    listenPort = portBazarr;
  };
  services.flaresolverr = {
    enable = true;
    port = lib.my.ports.flaresolverr;
  };

  # Setup PostgreSQL for seerr, radarr and sonarr
  # https://docs.seerr.dev/extending-seerr/database-config/
  services.postgresql = {
    ensureDatabases = [
      seerrDb
      radarrMainDb
      radarrLogDb
      sonarrMainDb
      sonarrLogDb
    ];
    ensureUsers = [
      {
        name = seerrDb;
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
      {
        name = "radarr";
        ensureDBOwnershipOf = [
          radarrMainDb
          radarrLogDb
        ];
        ensureClauses.login = true;
      }
      {
        name = "sonarr";
        ensureDBOwnershipOf = [
          sonarrMainDb
          sonarrLogDb
        ];
        ensureClauses.login = true;
      }
    ];
  };
  systemd.services.seerr = {
    wants = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
    environment = {
      DB_TYPE = "postgres";
      DB_SOCKET_PATH = "/run/postgresql";
      DB_USER = seerrDb;
      DB_NAME = seerrDb;
    };
    serviceConfig.StateDirectory = lib.mkForce "seerr"; # TODO: remove when stateVersion is bumped to 26.05
  };
  systemd.services.radarr = {
    wants = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
  };
  systemd.services.sonarr = {
    wants = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
  };

  age.secrets.diskstationSambaCredentials.file = secrets.host.diskstationSambaCredentials;

  # NAS mounts
  fileSystems."/media/diskstation" = {
    device = "//${diskstationAddress}/video";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.mount-timeout=5s";

        permissions = "uid=root,gid=${mediaGroup},file_mode=0664,dir_mode=0775";
      in
      [
        "${automount_opts},vers=2.0,credentials=${config.age.secrets.diskstationSambaCredentials.path},nobrl,${permissions}"
      ];
  };

  # Open Jellyfin local discovery ports
  # https://jellyfin.org/docs/general/networking/index.html
  networking.firewall.allowedUDPPorts = with lib.my.ports; [
    jellyfinAutoDiscoveryDlna
    jellyfinAutoDiscoveryClients
  ];

  services.nginx.virtualHosts =
    let
      autheliaRules = "group:arrs";
    in
    {
      ${domainJellyfin} = {
        enableACME = true;
        locations."/".proxyPass = "http://127.0.0.1:${toString portJellyfin}";
      };
      ${domainSeerr} = {
        enableACME = true;
        locations."/".proxyPass = "http://[::1]:${toString portSeerr}";
      };
      ${domainJellyseerr} = {
        enableACME = true;
        globalRedirect = domainSeerr;
      };
      ${domainRadarr} = {
        enableACME = true;
        inherit autheliaRules;
        restrictToNebula = true;
        autheliaHealthchecksPath = "/api/v3/health";
        locations."/" = {
          enableAuthelia = true;
          proxyPass = "http://[::1]:${toString portRadarr}";
        };
      };
      ${domainSonarr} = {
        enableACME = true;
        inherit autheliaRules;
        restrictToNebula = true;
        autheliaHealthchecksPath = "/api/v3/health";
        locations."/" = {
          enableAuthelia = true;
          proxyPass = "http://[::1]:${toString portSonarr}";
        };
      };
      ${domainJackett} = {
        enableACME = true;
        inherit autheliaRules;
        restrictToNebula = true;
        autheliaHealthchecksPath = "/health";
        locations."/" = {
          enableAuthelia = true;
          proxyPass = "http://127.0.0.1:${toString portJackett}";
        };
      };
      ${domainBazarr} = {
        enableACME = true;
        inherit autheliaRules;
        restrictToNebula = true;
        autheliaHealthchecksPath = "/api/system/health";
        locations."/" = {
          enableAuthelia = true;
          proxyPass = "http://127.0.0.1:${toString portBazarr}";
        };
      };
    };

  my.services.authelia.oauthClients = [
    # See https://www.authelia.com/integration/openid-connect/jellyfin/ for Jellyfin configuration
    {
      client_id = "nHnUxwHb5eNaT8g4N0mn3puk_cJqXUFivkjbpmoPY5wAd39bX.o7Q~wyRCOft5xWrcXDhuz6";
      client_name = "Jellyfin";
      client_secret = "$pbkdf2-sha512$310000$st30Kt4h4p.GYEOGo5Ez3A$/VWY8uCeQAXNWYpej6CEvm4WLhNorwo45Mou7u21mfsePIwxPYDMnHrobnviVTBl512plGxmsGenomJk.cT2tQ";
      redirect_uris = [
        "https://${domainJellyfin}/sso/OID/redirect/authelia"
      ];
      scopes = [
        "openid"
        "profile"
        "groups"
      ];
      policy = "one_factor";
      subject = "group:jellyfin";

      require_pkce = true;
      pkce_challenge_method = "S256";
      token_endpoint_auth_method = "client_secret_post";
    }
  ];

  users.groups.${mediaGroup} = { };
  users.users = {
    ${config.services.radarr.user}.extraGroups = [
      mediaGroup
      transmissionGroup
    ];
    ${config.services.sonarr.user}.extraGroups = [
      mediaGroup
      transmissionGroup
    ];
    ${config.services.bazarr.user}.extraGroups = [ mediaGroup ];
  };

  modules.impermanence.directories = [
    config.services.jellyfin.dataDir
    # also persist cache so we don't have to fetch metadata on every reboot
    config.services.jellyfin.cacheDir

    (lib.my.toPrivateStateDirectory config.services.seerr.configDir)
    config.services.radarr.dataDir
    config.services.sonarr.dataDir
    config.services.jackett.dataDir
    bazarrDirectory
  ];

  modules.services.restic.paths = [
    config.services.jellyfin.dataDir
    (lib.my.toPrivateStateDirectory config.services.seerr.configDir)
    config.services.radarr.dataDir
    config.services.sonarr.dataDir
    config.services.jackett.dataDir
    bazarrDirectory
  ];
  modules.services.restic.exclude = [
    "${config.services.jellyfin.dataDir}/log"
    "${config.services.jellyfin.dataDir}/metadata/livetv"
    "${config.services.jellyfin.dataDir}/transcode"
    "${lib.my.toPrivateStateDirectory config.services.seerr.configDir}/cache"
    "${lib.my.toPrivateStateDirectory config.services.seerr.configDir}/logs"
    "${config.services.radarr.dataDir}/logs"
    "${config.services.sonarr.dataDir}/logs"
    "${config.services.jackett.dataDir}/log.txt"
    "${bazarrDirectory}/log"
  ];
}
