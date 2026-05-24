# Configuration for Immich on Hera
{
  config,
  lib,
  secrets,
  ...
}:
let
  cfg = config.services.immich;

  photosLocation = "/persist/immich";
  photosLocationNfs = "/mnt/diskstation/immich";

  domain = "photos.diogotc.com";
  port = lib.my.ports.immich;

  oauthClientId = "geTzW3w4Q7ifXZTkNRPqk7sb.PL8yd1OD7mpORuqk8wFTM0mvITg-095msLn4_jWcxhRYm8O";
  oauthScopes = [
    "openid"
    "email"
    "profile"
  ];
in
{
  # Ensure that the NFS server has the same UID/GID
  users.users.${cfg.user}.uid = 15015;
  users.groups.${cfg.group}.gid = 15015;

  age.secrets.immichClientSecret.file = secrets.host.immichClientSecret;
  age.secrets.immichSmtpPassword.file = secrets.host.immichSmtpPassword;

  services.immich = {
    inherit port;

    enable = true;
    mediaLocation = photosLocation;

    settings = {
      # disable built-in database backup; we already have our own
      backup.database.enabled = false;

      # domain for public share links
      server.externalDomain = "https://${domain}";

      # import faces from EXIF data
      metadata.faces.import = true;

      # move assets to the `library` directory after uploading
      storageTemplate.enabled = true;

      # disable update checker
      newVersionCheck.enabled = false;

      notifications = {
        smtp = {
          enabled = true;
          from = "Immich <${lib.my.mkRobotsEmail "immich"}>";
          replyTo = "Immich Admin <${lib.my.mkDtcEmail "immich.admin"}>";
          transport = {
            host = "mail.diogotc.com";
            ignoreCert = false;
            password._secret = config.age.secrets.immichSmtpPassword.path;
            username = lib.my.mkRobotsEmail "immich";
            port = 465;
            secure = true;
          };
        };
      };

      oauth = {
        autoLaunch = true;
        autoRegister = true; # we limit who can register in authelia
        buttonText = "Login with Authelia";
        clientId = oauthClientId;
        clientSecret._secret = config.age.secrets.immichClientSecret.path;
        enabled = true;
        issuerUrl = "https://auth.diogotc.com/.well-known/openid-configuration";
        scope = lib.concatStringsSep " " oauthScopes;
        signingAlgorithm = "RS256";
        profileSigningAlgorithm = "none";
        storageLabelClaim = "preferred_username";
        storageQuotaClaim = "immich_quota";
      };
    };
  };

  systemd.services.immich-server = {
    # We must set the UMask of the Immich service, so new files can be read by the group as well,
    # in order for restic backups to work properly across NFS.
    serviceConfig.UMask = lib.mkForce "0027"; # default is 0077
  };

  systemd.tmpfiles.rules = [ "d ${photosLocation} 0750 ${cfg.user} ${cfg.group}" ];

  fileSystems =
    let
      mkBindMount =
        dir:
        lib.nameValuePair "${photosLocation}/${dir}" {
          depends = [
            "/mnt/diskstation"
            "/persist"
          ];
          device = "${photosLocationNfs}/${dir}";
          fsType = "none";
          options = [
            "bind"
            # since /mnt/diskstation is an automount, this also has to be
            # otherwise it won't remount when that network share is remounted
            "x-systemd.automount"
            "noauto"
          ];
        };
    in
    builtins.listToAttrs [
      (mkBindMount "library")
      (mkBindMount "encoded-video")
    ];

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
      # https://immich.app/docs/administration/reverse-proxy#nginx-example-config
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout 600s;
      '';
    };
  };

  my.services.authelia.oauthClients = [
    {
      client_id = oauthClientId;
      client_name = "Immich";
      client_secret = "$pbkdf2-sha512$310000$Z336P2rugr/JOEiMIvRU/w$H9YnpqQhXB8qrG3L8NnndYoBunQCxj/9cNffZ5IIgmqQXwL/06bVgUFogCuLkPZrvEUqlFs48.TCOjDqkmH/WA";
      redirect_uris = [
        "https://${domain}/auth/login"
        "https://${domain}/user-settings"
        "app.immich:///oauth-callback"
      ];
      scopes = oauthScopes;
      policy = "two_factor";
      subject = "group:immich";
      token_endpoint_auth_method = "client_secret_post";
    }
  ];

  modules.impermanence.directories = [
    # Persist downloaded models so they don't have to be downloaded every boot
    config.services.immich.machine-learning.environment.MACHINE_LEARNING_CACHE_FOLDER
  ];

  # https://immich.app/docs/administration/backup-and-restore
  modules.services.restic.paths = [
    "${photosLocationNfs}/library"
    "${photosLocation}/upload"
    "${photosLocation}/profile"
  ];

  # Unfortunately, CAP_DAC_READ_SEARCH does not work over NFS,
  # so we need to give read permissions to the restic user/group.
  # Ensure that the NFS server has the same UID/GID
  users.users.restic.uid = 15016;
  users.groups.restic.gid = 15016;
  # Additionally, the service must be in the immich group to read files and list directories
  systemd.services."restic-backups-systemBackup".serviceConfig.SupplementaryGroups = [ "immich" ];
}
