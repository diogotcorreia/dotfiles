# URL shortner
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  domain = "s.diogotc.com";
  port = lib.my.ports.chhotoUrl;

  stateDir = "/var/lib/private/chhoto-url";
in
{
  age.secrets.chhotoUrlEnv.file = secrets.host.chhotoUrlEnv;

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  systemd.services.chhoto-url = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      port = toString port;
      site_url = "https://${domain}";
    };
    serviceConfig = {
      DevicePolicy = "closed";
      DynamicUser = true;
      ExecStart = "${lib.getExe pkgs.my.chhoto-url}";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = [ "native" ];
      SystemCallFilter = [ "@system-service" ];
      StateDirectory = baseNameOf stateDir;
      ReadWritePaths = "/var/lib/${baseNameOf stateDir}";
      WorkingDirectory = "/var/lib/${baseNameOf stateDir}";

      # contains "password=<password>"
      EnvironmentFile = config.age.secrets.chhotoUrlEnv.path;
    };
  };

  modules.impermanence.directories = [ stateDir ];

  modules.services.restic.paths = [ stateDir ];
}
