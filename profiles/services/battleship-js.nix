# Battleships game
{
  lib,
  pkgs,
  ...
}: let
  port = lib.my.ports.battleships;
  domain = "battleships.diogotc.com";
in {
  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      root = "${pkgs.my.battleship-js.client}/build/";
      locations."/" = {
        index = "index.html";
        tryFiles = "$uri $uri/ /index.html";
      };
      locations."/socket.io" = {
        proxyPass = "http://[::1]:${toString port}";
      };
    };
  };

  systemd.services.battleship-js = {
    environment = {
      PORT = toString port;
    };

    description = "A Battleship game made for the web";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.my.battleship-js.server;

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
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
    };
  };
}
