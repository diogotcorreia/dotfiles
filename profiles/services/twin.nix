# Triton Web INterface
{
  config,
  lib,
  pkgs,
  ...
}: let
  port = lib.my.ports.twin;
  domain = "twin.rexcantor64.com";

  dataDir = "/var/lib/private/twin";

  dbUsername = "twin";
  dbName = "triton";
in {
  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      root = "${pkgs.my.twin.frontend}/build/";
      locations."/" = {
        index = "index.html";
        tryFiles = "$uri $uri/ /index.html";
      };
      locations."/api" = {
        proxyPass = "http://[::1]:${toString port}";
        extraConfig = ''
          client_max_body_size 10M;
        '';
      };
    };
  };

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [{name = dbUsername;}];
    ensureDatabases = [dbName];
  };
  systemd.services.postgresql.serviceConfig.ExecStartPost = let
    sqlFile = pkgs.writeText "twin-postgresql-setup.sql" ''
      GRANT SELECT ON TABLE "twin_tokens" TO "${dbUsername}";
    '';
  in [
    ''
      ${lib.getExe' config.services.postgresql.package "psql"} -d "${dbName}" -f "${sqlFile}"
    ''
  ];

  systemd.services.twin = {
    environment = {
      PORT = toString port;
      DB_URL = "postgresql:///${dbName}?host=/run/postgresql";
      STATE_DIR = dataDir;
    };

    description = "Triton Web INterface";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.my.twin.backend;

      Type = "simple";
      Restart = "on-failure";
      RestartSec = 3;
      DynamicUser = true;

      StateDirectory = baseNameOf dataDir;
      StateDirectoryMode = "0700";

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
    };
  };

  modules.impermanence.directories = [dataDir];
}
