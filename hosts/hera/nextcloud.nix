# Configuration for Nextcloud on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domain = "cloud.diogotc.com";
  collaboraDomain = "office.diogotc.com";

  collaboraPort = lib.my.ports.collabora-online;

  dbUsername = "nextcloud";
  dbDatabaseName = "nextcloud";
in
{
  age.secrets.nextcloudSecrets = {
    file = secrets.host.nextcloudSecrets;
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = domain;
    https = true;
    database.createLocally = true; # automatically uses pgsql through sockets
    configureRedis = true;
    maxUploadSize = "2G";
    config = {
      adminpassFile = toString (pkgs.writeText "nc-first-install-pwd" "changeMeAfterFirstInstallPlease");
      dbtype = "pgsql";
      dbuser = dbUsername;
      dbname = dbDatabaseName;
    };
    phpOptions = {
      "opcache.interned_strings_buffer" = "16";
      "opcache.validate_timestamps" = "0"; # disable opcache invalidation; flushed on nixos activation script
      "opcache.jit" = "1255";
      "opcache.jit_buffer_size" = "128M";
    };
    settings = {
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
      overwriteprotocol = "https";

      # NixOS handles updates for us, no need to check for it
      updatechecker = false;

      default_phone_region = "PT";

      "overwrite.cli.url" = "https://${domain}/";
      "upgrade.disable-web" = true;
      maintenance_window_start = 2;

      mail_from_address = "nextcloud";
      mail_smtpmode = "smtp";
      mail_sendmailmode = "smtp";
      mail_domain = "robots.diogotc.com";
      mail_smtpauthtype = "LOGIN";
      mail_smtpauth = true;
      mail_smtphost = "mail.diogotc.com";
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_smtpname = lib.my.mkRobotsEmail "nextcloud";
      # mail_smtppassword as secret
    };
    # Has:
    # mail_smtppassword
    # instanceid
    # passwordsalt
    # secret
    secretFile = config.age.secrets.nextcloudSecrets.path;

    appstoreEnable = false;
    extraAppsEnable = true;
    extraApps = with config.services.nextcloud.package.packages.apps; {
      inherit
        calendar
        contacts
        cookbook
        cospend
        deck
        gpoddersync # podcasts sync service
        nextpod
        notes
        polls
        richdocuments # Collabora Online for Nextcloud - https://apps.nextcloud.com/apps/richdocuments
        tasks
        twofactor_webauthn
        ;
    };
  };

  services.collabora-online = {
    enable = true;
    port = collaboraPort;
    settings = {
      # Rely on reverse proxy for SSL
      ssl = {
        enable = false;
        termination = true;
      };

      net = {
        listen = "loopback";
        post_allow.host = [ "::1" ];
      };
      storage.wopi = {
        "@allow" = true;
        host = [ domain ];
      };
      server_name = collaboraDomain;
    };
  };

  systemd.services.nextcloud-config-collabora =
    let
      inherit (config.services.nextcloud) occ;

      wopi_url = "http://[::1]:${toString collaboraPort}";
      public_wopi_url = "https://${collaboraDomain}";
      wopi_allowlist = lib.concatStringsSep "," [
        "127.0.0.1"
        "::1"
      ];
    in
    {
      wantedBy = [ "multi-user.target" ];
      after = [
        "nextcloud-setup.service"
        "coolwsd.service"
      ];
      requires = [ "coolwsd.service" ];
      script = ''
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_url --value ${lib.escapeShellArg wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments public_wopi_url --value ${lib.escapeShellArg public_wopi_url}
        ${occ}/bin/nextcloud-occ config:app:set richdocuments wopi_allowlist --value ${lib.escapeShellArg wopi_allowlist}
        ${occ}/bin/nextcloud-occ richdocuments:setup
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };

  networking.hosts = {
    "127.0.0.1" = [
      domain
      collaboraDomain
    ];
    "::1" = [
      domain
      collaboraDomain
    ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
    };
    ${collaboraDomain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString collaboraPort}";
    };
  };

  # Pin nextcloud user's UID and GID, otherwise files may change owner
  users.users.nextcloud.uid = 900;
  users.groups.nextcloud.gid = 900;

  # Due to PHP's realpath cache, every time the activation scripts run,
  # Nextcloud stops working for a brief moment.
  # This happens because the secrets handled by agenix change their path,
  # and PHP does not follow the new destination of the symlink until the cache expires.
  # Additionally, we are now disabling OPCache's invalidation, given that files do not change
  # without a NixOS activation.
  # This reloads php-fpm after agenix has updated secrets, so that it clears the cache.
  system.activationScripts.nextcloud-reload = {
    text = ''
      if [ "$NIXOS_ACTION" == "switch" ]; then
        echo phpfpm-nextcloud.service > /run/nixos/activation-reload-list
      fi
    '';
    deps = [ "agenix" ];
  };

  modules.impermanence.directories = [ config.services.nextcloud.home ];
  modules.services.restic.paths = [ config.services.nextcloud.home ];
}
