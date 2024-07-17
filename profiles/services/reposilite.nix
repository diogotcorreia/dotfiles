# Lightweight Maven repository
# https://reposilite.com
{
  lib,
  pkgs,
  ...
}: let
  domain = "repo.diogotc.com";
  port = 5100;

  stateDir = "/var/lib/reposilite";

  flags = [
    "--working-directory=${stateDir}"
    "--port=${toString port}"
  ];
in {
  security.acme.certs.${domain} = {};

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  systemd.services."reposilite" = {
    description = "Reposilite - Maven repository";

    wantedBy = ["multi-user.target"];

    script = "${lib.getExe pkgs.my.reposilite} ${lib.escapeShellArgs flags}";

    serviceConfig = {
      StateDirectory = "reposilite";
      StateDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = 10;
      DynamicUser = true;

      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      LockPersonality = true;
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      RemoveIPC = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = ["@system-service" "~@privileged @resources"];
    };
  };

  modules.impermanence.directories = [stateDir];

  modules.services.restic.paths = [stateDir];
}
