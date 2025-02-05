# various custom experimental scripts
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  port = 7649;
  domain = "labs.diogotc.com";

  dbUsername = "dtc-labs";
  dbName = "triton";
in {
  age.secrets = {
    # Contains:
    # PAYPAL_CLIENT_ID
    # PAYPAL_CLIENT_SECRET
    # PAYPAL_SPREADSHEET_ID
    dtcLabsEnv.file = secrets.host.dtcLabsEnv;

    dtcLabsTokenJson.file = secrets.host.dtcLabsTokenJson;
    dtcLabsCredentialsJson.file = secrets.host.dtcLabsCredentialsJson;
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [{name = dbUsername;}];
    ensureDatabases = [dbName];
  };
  systemd.services.postgresql.serviceConfig.ExecStartPost = let
    sqlFile = pkgs.writeText "dtc-labs-postgresql-setup.sql" ''
      GRANT INSERT ON TABLE "triton_buyers" TO "${dbUsername}";
    '';
  in [
    ''
      ${lib.getExe' config.services.postgresql.package "psql"} -d "${dbName}" -f "${sqlFile}"
    ''
  ];

  systemd.services.dtc-labs = {
    environment = {
      PORT = toString port;

      TRITON_DB_URL = "postgresql:///${dbName}?host=/run/postgresql";

      PAYPAL_MODE = "live";

      # use systemd credentials to load these without chown
      GSHEETS_TOKEN_PATH = "%d/token.json";
      GSHEETS_CREDENTIALS_PATH = "%d/credentials.json";
    };

    description = "Experimental code snippets for dtc";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.my.dtc-labs;

      Type = "simple";
      Restart = "on-failure";
      RestartSec = 3;
      DynamicUser = true;

      LoadCredential = [
        "token.json:${config.age.secrets.dtcLabsTokenJson.path}"
        "credentials.json:${config.age.secrets.dtcLabsCredentialsJson.path}"
      ];

      # Hardening
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateUsers = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateMounts = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;

      EnvironmentFile = config.age.secrets.dtcLabsEnv.path;
    };
  };
}
