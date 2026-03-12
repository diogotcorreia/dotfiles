# Configuration for Paperless-ngx on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domain = "paperless.diogotc.com";
  port = lib.my.ports.paperless;

  dataDir = config.services.paperless.dataDir;

  oauthClientId = "fA5VQtlA~j3YJGGF-lsTMoN9bwMkUU5rJbU.iWNgRMF6bFNgl9O5FzBrziGi.rhuU-u40q_L";
  oauthScopes = [
    "openid"
    "email"
    "profile"
  ];
in
{
  age.secrets.paperlessClientSecret.file = secrets.host.paperlessClientSecret;

  services.paperless = {
    enable = true;
    address = "[::1]";
    inherit port domain;

    configureNginx = true;
    database.createLocally = true;

    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng+por+swe";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
        # Allow OCRmyPDF to modify signed PDFs, since original is also stored
        # https://github.com/paperless-ngx/paperless-ngx/issues/7383
        invalidate_digital_signatures = true;
      };

      # Authentication via authelia
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
        openid_connect = {
          OAUTH_PKCE_ENABLED = "True";
          SCOPES = oauthScopes;
          APPS = [
            {
              provider_id = "authelia";
              name = "Authelia";
              client_id = oauthClientId;
              # secret will be added dynamically, see below
              #secret = "";
              settings.server_url = "https://auth.diogotc.com/.well-known/openid-configuration";
            }
          ];
        };
      };
      PAPERLESS_SOCIALACCOUNT_ALLOW_SIGNUPS = true;
      PAPERLESS_DISABLE_REGULAR_LOGIN = true;
      PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;

      # GRANIAN does not support the brackets around IPv6 addresses, but we need it for the nginx config
      GRANIAN_HOST = lib.removePrefix "[" (lib.removeSuffix "]" config.services.paperless.address);
    };
  };

  # Add secret to PAPERLESS_SOCIALACCOUNT_PROVIDERS
  systemd.services.paperless-web = {
    serviceConfig.LoadCredential = [
      "oidcSecret:${config.age.secrets.paperlessClientSecret.path}"
    ];
    script = lib.mkBefore ''
      oidcSecret="$(< "$CREDENTIALS_DIRECTORY"/oidcSecret)"
      export PAPERLESS_SOCIALACCOUNT_PROVIDERS="$(
        ${lib.getExe pkgs.jq} <<< "$PAPERLESS_SOCIALACCOUNT_PROVIDERS" \
          --compact-output \
          --arg oidcSecret "$oidcSecret" \
          '.openid_connect.APPS.[0].secret = $oidcSecret'
      )"
    '';
  };

  services.nginx.virtualHosts.${domain}.enableACME = true;

  my.services.authelia.oauthClients = [
    {
      client_id = oauthClientId;
      client_name = "Paperless";
      client_secret = "$pbkdf2-sha512$310000$XF9GuTSbf3X6EwP3.c6TYg$jXSDZ8f3dbxgeMKlwPu0.Ax7L0l37u4Dcy55YKEvSj0kege3YTVckn7RaOgul8PtpmHcEz92DwHfzt2PRqL1Jw";
      redirect_uris = [
        "https://${domain}/accounts/oidc/authelia/login/callback/"
      ];
      scopes = oauthScopes;
      policy = "two_factor";
      subject = "group:paperless";
      token_endpoint_auth_method = "client_secret_basic";
    }
  ];

  modules.impermanence.directories = [ dataDir ];

  modules.services.restic.paths = [ dataDir ];
  modules.services.restic.exclude = [ "${dataDir}/log" ];
}
