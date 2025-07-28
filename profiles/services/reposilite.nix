# Lightweight Maven repository
# https://reposilite.com
{
  lib,
  pkgs,
  ...
}:
let
  domain = "repo.diogotc.com";
  port = lib.my.ports.reposilite;

  stateDir = "/var/lib/reposilite";

  user = "reposilite";
  group = user;

  flags = [
    "--working-directory=${stateDir}"
    "--port=${toString port}"
    "--hostname=::1"
    # use unix sockets (requires custom package)
    "--database=postgresql localhost ${user}?socketFactory=org.newsclub.net.unix.AFUNIXSocketFactory$FactoryArg&socketFactoryArg=/run/postgresql/.s.PGSQL.5432 ${user} password"
  ];
in
{
  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = user;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ user ];
  };

  systemd.services."reposilite" = {
    description = "Reposilite - Maven repository";

    wantedBy = [ "multi-user.target" ];

    script = "${lib.getExe pkgs.my.reposilite-junixsocket} ${lib.escapeShellArgs flags}";

    serviceConfig = {
      StateDirectory = "reposilite";
      StateDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = 10;
      User = user;
      Group = group;

      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      LockPersonality = true;
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      RemoveIPC = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = [
        "@system-service"
        "~@privileged @resources"
      ];
    };
  };

  users.users.${user} = {
    inherit group;
    home = stateDir;
    isSystemUser = true;
  };
  users.groups.${group} = { };

  modules.impermanence.directories = [ stateDir ];

  modules.services.restic.paths = [ stateDir ];
}
