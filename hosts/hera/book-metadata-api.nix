# Configuration for Book Metadata API on Hera
{
  lib,
  pkgs,
  ...
}:
let
  domain = "book-api.diogotc.com";
  port = lib.my.ports.bookMetadataApi;

  stateDirectory = "/var/lib/book-metadata-api";
in
{
  systemd.services.book-metadata-api = {
    description = "Book Metadata API";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      PORT = toString port;
      # chromium needs XDG_CONFIG_HOME to exist and be writable
      XDG_CONFIG_HOME = "/var/cache/book-metadata-api";
    };

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "book-metadata-api";
      StateDirectoryMode = "0700";
      CacheDirectory = "book-metadata-api";
      CacheDirectoryMode = "0700";
      UMask = "0077";
      WorkingDirectory = stateDirectory;
      ExecStart = "${pkgs.my.book-metadata-api}/bin/book-metadata-api";
      Restart = "on-failure";
      TimeoutSec = 15;

      # Hardening
      LockPersonality = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictRealtime = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = [
        "net"
        "pid"
        "user"
      ];
      CapabilityBoundingSet = [
        "~CAP_BLOCK_SUSPEND"
        "~CAP_BPF"
        "~CAP_CHOWN"
        "~CAP_IPC_LOCK"
        "~CAP_MKNOD"
        "~CAP_NET_ADMIN"
        "~CAP_NET_RAW"
        "~CAP_PERFMON"
        "~CAP_SYSLOG"
        "~CAP_SYS_ADMIN"
        "~CAP_SYS_BOOT"
        "~CAP_SYS_MODULE"
        "~CAP_SYS_PACCT"
        "~CAP_SYS_PTRACE"
        "~CAP_SYS_TIME"
        "~CAP_WAKE_ALARM"
      ];
      SystemCallFilter = [
        "~@chown"
        "~@clock"
        "~@cpu-emulation"
        "~@debug"
        "~@keyring"
        "~@memlock"
        "~@module"
        "~@obsolete"
        "~@pkey"
        "~@raw-io"
        "~@reboot"
        "~@setuid"
        "~@swap"
        "~@timer"
      ];
      SystemCallErrorNumber = "EPERM";
      SystemCallArchitectures = "native";
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  modules.impermanence.directories = [
    (lib.my.toPrivateStateDirectory stateDirectory)
  ];
}
