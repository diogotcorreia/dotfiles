{
  config,
  lib,
  secrets,
  ...
}:
let
  cfg = config.services.linkwarden;

  domain = "linkwarden.diogotc.com";
  port = lib.my.ports.linkwarden;

  oauthClientId = ".yZfgQ3cIrw~ljqRrJ2e93y_MuVTe~RXrc.N-.lO9I.cbUrTj__.kzdB_355.ilWIJugdPbk";
  oauthScopes = [
    "openid"
    "email"
    "profile"
  ];

  commonSecretOptions = {
    owner = cfg.user;
    group = cfg.group;
  };
in
{
  age.secrets.linkwardenClientSecret = commonSecretOptions // {
    file = secrets.host.linkwardenClientSecret;
  };
  age.secrets.linkwardenNextSecret = commonSecretOptions // {
    file = secrets.host.linkwardenNextSecret;
  };

  services.linkwarden = {
    inherit port;
    enable = true;

    secretFiles = {
      NEXTAUTH_SECRET = config.age.secrets.linkwardenNextSecret.path;
      AUTHELIA_CLIENT_SECRET = config.age.secrets.linkwardenClientSecret.path;
    };

    environment = {
      NEXTAUTH_URL = "https://${domain}/api/v1/auth";
      NEXT_PUBLIC_CREDENTIALS_ENABLED = "false";
      NEXT_PUBLIC_AUTHELIA_ENABLED = "true";
      AUTHELIA_WELLKNOWN_URL = "https://auth.diogotc.com/.well-known/openid-configuration";
      AUTHELIA_CLIENT_ID = oauthClientId;
    };
  };

  systemd.services.linkwarden-worker.serviceConfig = {
    # SIGTERM does not work to terminate the worker, it needs to be SIGINT
    # https://github.com/linkwarden/linkwarden/blob/v2.14.0/apps/worker/index.ts#L14
    KillSignal = "SIGINT";
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  my.services.authelia.oauthClients = [
    {
      client_id = oauthClientId;
      client_name = "Linkwarden";
      client_secret = "$pbkdf2-sha512$310000$KyATXVOFb/YlI7xk9vwZjQ$/soVrgN7hNR6JLWlI0HE/cnNYIKrKkT7XAvIqF/th/Rx/hj1XtFmR5QScNt/7Z6aXfoqqnnwGXbSujf39LZGzg";
      redirect_uris = [
        "https://${domain}/api/v1/auth/callback/authelia"
      ];
      scopes = oauthScopes;
      policy = "two_factor";
      subject = "group:linkwarden";
    }
  ];

  modules.impermanence.directories = [
    cfg.storageLocation
  ];

  modules.services.restic.paths = [
    cfg.storageLocation
  ];
}
