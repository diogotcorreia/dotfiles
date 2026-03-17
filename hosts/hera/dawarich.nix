# Configuration for Dawarich (Location Timeline) on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domain = "location.diogotc.com";
  port = lib.my.ports.dawarich;

  oauthClientId = "TiGDNjVpH.SH5Hs4tri8JWAwsfqChu19jbyDB1XeOI6hRBqhrCluFuCxXfhGH.QyviY~0.Cs";
  oauthScopes = [
    "openid"
    "email"
    "profile"
  ];
  oauthRedirectUri = "https://${domain}/users/auth/openid_connect/callback";
in
{
  age.secrets.dawarichEnv.file = secrets.host.dawarichEnv;
  age.secrets.dawarichSecretKeyBase.file = secrets.host.dawarichSecretKeyBase;

  services.dawarich = {
    enable = true;
    webPort = port;
    localDomain = domain;
    secretKeyBaseFile = config.age.secrets.dawarichSecretKeyBase.path;
    environment = {
      STORE_GEODATA = "true";
      NOMINATIM_API_HOST = "ams.nominatim.grapheneos.org";
      NOMINATIM_API_USE_HTTPS = "true";
      ENABLE_TELEMETRY = "false";

      # oauth
      OIDC_CLIENT_ID = oauthClientId;
      # OIDC_CLIENT_SECRET in env
      OIDC_ISSUER = "https://auth.diogotc.com";
      OIDC_REDIRECT_URI = oauthRedirectUri;
      OIDC_AUTO_REGISTER = "true";
      OIDC_PROVIDER_NAME = "Authelia";
      ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
    };

    extraEnvFiles = [
      # Contains:
      # - OIDC_CLIENT_SECRET
      config.age.secrets.dawarichEnv.path
    ];

    package = pkgs.dawarich.overrideAttrs (prev: {
      postPatch = prev.postPatch or "" + ''
        substituteInPlace config/initializers/03_dawarich_settings.rb \
          --replace-fail "@photon_uses_komoot_io ||= PHOTON_API_HOST == 'photon.komoot.io'" "@photon_uses_komoot_io ||= (PHOTON_API_HOST == 'photon.komoot.io' || nominatim_enabled?)"
      '';
    });
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    autheliaRules = "group:location";
    # Require auth for everything except upload and health endpoints
    locations = {
      "/" = {
        enableAuthelia = true;
      };
      "= /api/v1/owntracks/points" = {
        tryFiles = "$uri @proxy";
        extraConfig = ''
          limit_except POST {
            deny all;
          }
        '';
      };
      "= /api/v1/health" = {
        tryFiles = "$uri @proxy";
        extraConfig = ''
          limit_except GET {
            deny all;
          }
        '';
      };
    };
  };

  my.services.authelia.oauthClients = [
    {
      client_id = oauthClientId;
      client_name = "Dawarich";
      client_secret = "$pbkdf2-sha512$310000$8DBJI9gH/xFFL/teZIBIhw$90RXCgMqVmWe6nmYcEfFL0vuk1KJXjTrBV96Rqe8rY6.mRzPq3o0dRV3PnZHIXLH.4lzyisNYXc14yUfw/wddQ";
      redirect_uris = [
        oauthRedirectUri
      ];
      scopes = oauthScopes;
      policy = "two_factor";
      subject = "group:dawarich";
      token_endpoint_auth_method = "client_secret_basic";
    }
  ];
}
