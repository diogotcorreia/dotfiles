# modules/services/dnsoverhttps.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Local DNS proxy server to use Cloudflare's DNS over HTTPS.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.modules.services.dnsoverhttps;

  upstreams = [
    "sdns://AgcAAAAAAAAABzEuMS4xLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5" # 1.1.1.1
    "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5" # 1.0.0.1
    "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTExMV0AIDFkb3QxZG90MWRvdDEuY2xvdWRmbGFyZS1kbnMuY29tCi9kbnMtcXVlcnk" # [2606:4700:4700::1111]
    "sdns://AgcAAAAAAAAAFlsyNjA2OjQ3MDA6NDcwMDo6MTAwMV0AIDFkb3QxZG90MWRvdDEuY2xvdWRmbGFyZS1kbnMuY29tCi9kbnMtcXVlcnk" # [2606:4700:4700::1001]
  ];
in {
  options.modules.services.dnsoverhttps = {
    enable = mkEnableOption "Cloudflare DNS over HTTPS proxy";

    all-interfaces = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Whether the dns proxy should listen on all interfaces or
        only on the loopback interface.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      nameservers = ["127.0.0.53"];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    systemd.services.dnsproxy = let
      extraArgs = [
        "--cache"
        "--listen=${
          if cfg.all-interfaces
          then "0.0.0.0"
          else "127.0.0.53"
        }"
      ];

      finalArgs = map (upstream: "--upstream=${upstream}") upstreams ++ extraArgs;
    in {
      description = "dnsproxy client";
      wants = [
        "network-online.target"
        "nss-lookup.target"
      ];
      before = [
        "nss-lookup.target"
      ];
      wantedBy = [
        "multi-user.target"
      ];
      serviceConfig = {
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        CacheDirectory = "dnsproxy";
        DynamicUser = true;
        ExecStart = "${lib.getExe pkgs.dnsproxy} ${lib.escapeShellArgs finalArgs}";
        LockPersonality = true;
        LogsDirectory = "dnsproxy";
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        NonBlocking = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        Restart = "always";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RuntimeDirectory = "dnsproxy";
        StateDirectory = "dnsproxy";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@chown"
          "~@aio"
          "~@keyring"
          "~@memlock"
          "~@setuid"
          "~@timer"
        ];
      };
    };
  };
}
