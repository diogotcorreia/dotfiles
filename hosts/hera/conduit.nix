# Configuration for Conduit (Matrix Homeserver) on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.services.matrix-continuwuity;
  conduitDir = lib.my.toPrivateStateDirectory cfg.settings.global.database_path;

  serverName = "diogotc.com";
  domainConduit = "m.diogotc.com";
  domainElement = "chat.diogotc.com";

  # https://web-docs.element.dev/Element%20Web/config.html
  elementConfig = {
    default_server_name = serverName;
    disable_custom_urls = true;
    disable_guests = true;
    disable_login_language_selector = false;
    disable_3pid = true;
    brand = "DTC's Element";

    integrations_ui_url = "https://scalar.vector.im/";
    integrations_rest_url = "https://scalar.vector.im/api";
    integrations_widgets_urls = [
      "https://scalar.vector.im/_matrix/integrations/v1"
      "https://scalar.vector.im/api"
      "https://scalar-staging.vector.im/_matrix/integrations/v1"
      "https://scalar-staging.vector.im/api"
      "https://scalar-staging.riot.im/scalar/api"
    ];
    integrations_jitsi_widget_url = "https://scalar.vector.im/api/widgets/jitsi.html";

    default_country_code = "PT";

    show_labs_settings = true;
    features = { };
    default_federate = true;
    default_theme = "dark";
    room_directory = {
      servers = [ "diogotc.com" ];
    };
    setting_defaults = {
      breadcrumbs = true;
    };
    jitsi = {
      preferred_domain = "meet.element.io";
    };
    element_call = {
      url = "https://call.element.io";
      participant_limit = 8;
      brand = "Element Call";
    };
    map_style_url = "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx";
  };

  oauthClientId = "EAQV7ZOTs4lWrnCwfyFzCJUNWquGWkVWPe4GOQjcTu~~St2XlVD7qLULZsSqBEpBBeE8KZOp";
  oauthScopes = [
    "openid"
    "email"
    "profile"
  ];
in
{
  age.secrets.continuwuityClientSecret.file = secrets.host.continuwuityClientSecret;

  services.matrix-continuwuity = {
    enable = true;
    # TODO 26.11: use package from stable
    package = pkgs.unstable.matrix-continuwuity;
    group = config.services.nginx.group;
    settings = {
      global = {
        server_name = serverName;
        unix_socket_path = "/run/continuwuity/continuwuity.sock";
        new_user_displayname_suffix = "";

        # continuwuity provided vetted servers
        trusted_servers = [
          "codestorm.net"
          "starstruck.systems"
          "unredacted.org"
          "matrix.org"
        ];

        # hardcoded because of infinite recursion...
        database_backup_path = "/var/lib/continuwuity/backups";
        database_backups_to_keep = 1;
        admin_signal_execute = [ "server backup-database" ];

        well_known = {
          client = "https://${domainConduit}";
          server = "${domainConduit}:443";
        };

        oauth = {
          compatibility_mode = "exclusive";
          oidc = {
            discovery_url = "https://auth.diogotc.com";
            client_id = oauthClientId;
            client_secret_file = "/run/credentials/continuwuity.service/oidc_client_secret";
            additional_scopes = oauthScopes;

            prompt_for_localpart = false;
            preferred_username_claim = "preferred_username";
            email_claim = "email";
            profile_key_map = {
              displayname = "name";
            };
            profile_key_import_mode = "on_registration";
          };
        };
      };
    };
  };

  systemd.services.continuwuity = {
    serviceConfig = {
      LoadCredential = [
        "oidc_client_secret:${config.age.secrets.continuwuityClientSecret.path}"
      ];
    };
  };

  services.nginx.virtualHosts = {
    ${domainConduit} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations = {
        "/" = {
          proxyPass = "http://unix:${cfg.settings.global.unix_socket_path}";
          extraConfig = ''
            client_max_body_size ${toString cfg.settings.global.max_request_size};
          '';
        };
      };
    };
    ${domainElement} =
      let
        elementPkg = pkgs.element-web.override {
          conf = elementConfig;
        };
      in
      {
        enableACME = true;
        root = elementPkg;
      };
  };

  my.services.authelia.oauthClients = [
    {
      client_id = oauthClientId;
      client_name = "Matrix Continuwuity";
      client_secret = "$pbkdf2-sha512$310000$HqqdEf7nGa3J2RvVNs/4OQ$gfThmuGsAWtdejQtI4B2GD.vNuu4Jq/eozzjFUMBQ0f/GxpIhzoqxmE0bVSd8vNA1O5wd3/WIYBgmngdz9NAsw";
      redirect_uris = [
        "https://${domainConduit}/_continuwuity/oidc/complete"
      ];
      scopes = oauthScopes;
      policy = "two_factor";
      subject = "group:matrix";
      token_endpoint_auth_method = "client_secret_basic";

      # Continuwuity does not fetch the userinfo endpoint, so we need to ensure these claims are available in the token
      claims_policy = {
        id_token = [
          "preferred_username"
          "name"
          "email"
        ];
      };
    }
  ];

  modules.impermanence.directories = [
    conduitDir
  ];

  modules.services.restic = {
    # trigger backup using signal
    # unfortunately there's no way to know when the backup is done, but 5 seconds should be more than enough
    backupPrepareCommand = ''
      ${config.systemd.package}/bin/systemctl kill continuwuity.service --signal=SIGUSR2
      ${pkgs.coreutils}/bin/sleep 5
    '';
    paths = [
      "${conduitDir}/media"
      "${conduitDir}/backups"
    ];
  };

  # Allow the backup service to call systemctl kill on the continuwuity service
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user === "restic" && action.id === "org.freedesktop.systemd1.manage-units") {
        if (action.lookup("unit") === "continuwuity.service") {
          if (action.lookup("verb") === "kill") {
            return polkit.Result.YES;
          }
        }
      }
    });
  '';
}
