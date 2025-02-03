# Triton Discord bot
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  dbUsername = "triton-bot";
  dbName = "triton";
in {
  # Contains:
  # DISCORD_TOKEN
  age.secrets.tritonBotEnv.file = secrets.host.tritonBotEnv;

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [{name = dbUsername;}];
    ensureDatabases = [dbName];
  };
  systemd.services.postgresql.serviceConfig.ExecStartPost = let
    sqlFile = pkgs.writeText "triton-bot-postgresql-setup.sql" ''
      GRANT SELECT ON TABLE "triton_buyers" TO "${dbUsername}";
      GRANT SELECT, INSERT ON TABLE "twin_tokens" TO "${dbUsername}";
    '';
  in [
    ''
      ${lib.getExe' config.services.postgresql.package "psql"} -d "${dbName}" -f "${sqlFile}"
    ''
  ];

  systemd.services.triton-bot = {
    environment = {
      DB_URL = "postgresql:///${dbName}?host=/run/postgresql";
      VERIFICATION_CHANNEL = "523642981547376641";
      BUYER_ROLE = "407568245936226304";
      BOT_OWNER_ID = "218721510649626635";
    };

    description = "A Discord bot to verify purchases of Triton";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.my.triton-bot;

      Type = "simple";
      Restart = "on-failure";
      RestartSec = 3;
      DynamicUser = true;

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

      EnvironmentFile = config.age.secrets.tritonBotEnv.path;
    };
  };
}
