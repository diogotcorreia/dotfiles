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

  oauthClientId = "hzQo18_e2tV8HeaikIa-AqAE6iEShOmKDcDpGQxyrxKKXbygH94yOTIm~t3ZpPMEa06OFOOS";
  oauthScopes = [
    "openid"
    "email"
    "profile"
    "groups"
    "nextcloud_userinfo"
  ];

  inherit (config.services.nextcloud) occ;
in
{
  age.secrets.nextcloudSecrets = {
    file = secrets.host.nextcloudSecrets;
    owner = "nextcloud";
    group = "nextcloud";
  };
  age.secrets.nextcloudClientSecret.file = secrets.host.nextcloudClientSecret;

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
      "opcache.validate_timestamps" = "1";
      "opcache.revalidate_freq" = "60";
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

      user_oidc = {
        enrich_login_id_token_with_userinfo = true;
        userinfo_bearer_validation = true;
        auto_provision = true;
        soft_auto_provision = true; # allow login into existing accounts
        allow_multiple_user_backends = false; # redirect to authelia immediately
      };

      hide_login_form = true; # use ?direct=1 to bypass/login as root
      "auth.webauthn.enabled" = false; # using only oidc, that already uses webauthn
      allow_user_to_change_display_name = false; # does not work with oidc
      lost_password_link = "disabled";
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
        user_oidc
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

  # OAuth setup
  my.services.authelia = {
    ldapExtraAttributes = {
      # This is needed because Nextcloud does not support renaming users,
      # and some users on LDAP do not have the same username as in Nextcloud.
      nextcloudusername = {
        name = "nextcloud_username";
        value_type = "string";
      };
      nextcloudquota = {
        name = "nextcloud_quota";
        value_type = "integer";
      };
    };
    oauthClients = [
      {
        client_id = oauthClientId;
        client_name = "Nextcloud";
        client_secret = "$pbkdf2-sha512$310000$wfhYdQHkTMX5mTlcCjInYg$cMfbCHLcdD0TKrB23SfPYPrpnGwxcAaRawX8y0.6lx1fjgHoWMWBJE3kxKCJPfYCh.JLMsCv1z.c0SBKZNdtEA";
        redirect_uris = [
          "https://${domain}/apps/user_oidc/code"
        ];
        scopes = oauthScopes;
        policy = "two_factor";
        subject = "group:nextcloud";
        token_endpoint_auth_method = "client_secret_post";
      }
    ];
    oidcScopes.nextcloud_userinfo = {
      claims = [
        config.my.services.authelia.ldapExtraAttributes.nextcloudusername.name
        config.my.services.authelia.ldapExtraAttributes.nextcloudquota.name
      ];
    };
  };

  systemd.services.nextcloud-config-user-oidc = {
    enable = true;
    script = ''
      ${occ}/bin/nextcloud-occ user_oidc:provider Authelia \
        --discoveryuri="https://auth.diogotc.com/.well-known/openid-configuration" \
        --clientid=${lib.escapeShellArg oauthClientId} \
        --clientsecret=$(systemd-creds cat clientsecret) \
        --scope=${lib.escapeShellArg (lib.concatStringsSep " " oauthScopes)} \
        --unique-uid=0 \
        --resolve-nested-claims=1 \
        --mapping-uid="nextcloud_username | preferred_username" \
        --mapping-quota="nextcloud_quota" \
        --no-interaction
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "nextcloud-setup.service" ];

    serviceConfig = {
      LoadCredential = [
        "clientsecret:${config.age.secrets.nextcloudClientSecret.path}"
      ]
      ++ (config.systemd.services.phpfpm-nextcloud.serviceConfig.LoadCredential or [ ]);
      User = "nextcloud";
      Type = "oneshot";
    };
  };

  # Due to PHP's realpath cache, every time the activation scripts run,
  # Nextcloud stops working for a brief moment.
  # This happens because the secrets handled by agenix change their path,
  # and PHP does not follow the new destination of the symlink until the cache expires.
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
