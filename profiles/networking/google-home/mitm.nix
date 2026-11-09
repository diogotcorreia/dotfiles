# Thanks to the eMudhra CA compromise, we can man-in-the-middle Google Home devices
# to make them work (mostly) offline without talking back to Google.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Allowed hosts and URIs.
  # These are proxied to their respective upstreams.
  # TODO: Eventually it would be great to just serve these files statically.
  hosts = {
    "www.gstatic.com" = {
      allowedLocations = [
        "= /cast/sdk/libs/caf_receiver/v2/cast_receiver_framework.js"
        "= /cast/sdk/libs/caf_receiver/v3/cast_receiver_framework.js"
        "= /cast/sdk/libs/mediaplayer/1.0.0/media_player.js"
        "= /cast/sdk/libs/receiver/2.0.0/cast_receiver.js"
      ];
    };
    "ajax.googleapis.com" = {
      allowedLocations = [
        "= /ajax/libs/shaka-player/4.15.56/shaka-player.compiled.js"
      ];
    };
    "clients3.google.com" = {
      allowedLocations = [
        "= /cast/chromecast/device/app"
        "= /cast/chromecast/device/baseconfig"
      ];
    };
    "clients1.google.com" = {
      locations."/generate_204" = {
        return = 204;
      };
    };
    "connectivitycheck.gstatic.com" = {
      locations."/" = {
        return = 204;
      };
    };
    # We want to allow the Music Assistant "apps"
    "cast.music-assistant.io" = {
      allowedLocations = [
        "/"
      ];
    };
    "sendspin.github.io" = {
      allowedLocations = [
        "/cast"
      ];
    };
  };

  listen = [
    {
      addr = "192.168.2.1"; # vlan-iot-cloud on bro
      port = 80;
      ssl = false;
    }
    {
      addr = "192.168.2.1"; # vlan-iot-cloud on bro
      port = 443;
      ssl = true;
    }
  ];

  locationProxy = {
    proxyPass = "https://$host";
    recommendedProxySettings = false;
    proxyWebsockets = false;
  };

  locationBlock = {
    # Close connection
    return = 444;
  };

  mkHost =
    _name: cfg:
    let
      extraLocations = lib.listToAttrs (
        map (loc: lib.nameValuePair loc locationProxy) (cfg.allowedLocations or [ ])
      );
    in
    {
      inherit listen;
      forceSSL = false;
      addSSL = true;
      sslCertificate = "/var/lib/acme/gh-mitm.internal/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/gh-mitm.internal/key.pem";
      extraConfig = ''
        access_log /var/log/nginx/gh_mitm.log gh_mitm;
      '';

      locations = {
        "/" = locationBlock;
      }
      // extraLocations
      // (cfg.locations or { });
    };

  mkHosts = hosts: lib.mapAttrs mkHost hosts;
in
{
  services.nginx = {
    virtualHosts = (mkHosts hosts) // {
      # reject connections to unknown virtual hosts
      "gh_" = {
        inherit listen;
        default = true;
        serverName = "_";
        rejectSSL = true;
        locations."/" = {
          return = "444";
        };
        extraConfig = ''
          access_log /var/log/nginx/gh_mitm.log gh_mitm;
        '';
      };
    };

    commonHttpConfig = ''
      log_format gh_mitm '[$time_local] $remote_addr - $host:$server_port - "$request" $status $body_bytes_sent';
    '';
    resolver.addresses = [ "127.0.0.55" ];
  };

  # Generate a certificate for all domains we are intercepting,
  # signed by the leaked eMudhra CA.
  systemd.services."acme-gh-mitm" =
    let
      ext = lib.generators.toINIWithGlobalSection { } {
        globalSection = {
          basicConstraints = "critical,CA:FALSE";
          keyUsage = "critical,digitalSignature,keyEncipherment";
          extendedKeyUsage = "serverAuth";
          subjectAltName = "@alt_names";
        };
        sections = {
          alt_names = lib.pipe hosts [
            lib.attrNames
            (lib.imap1 (i: host: lib.nameValuePair "DNS.${toString i}" host))
            lib.listToAttrs
          ];
        };
      };
      extfile = pkgs.writeText "extfile" ext;
    in
    {
      wantedBy = [ "multi-user.target" ];
      after = [ "acme-setup.service" ];
      wants = [ "acme-setup.service" ];
      path = [ pkgs.openssl ];

      script = ''
        set -ex

        openssl genrsa -out server.key 2048
        openssl req -new -key server.key -out server.csr -subj "/CN=gh-mitm.internal"
        # NOTE: google home does not accept certificates with too long expiration, so keep it to 30 days just to be sure
        openssl x509 -req -in server.csr -CA "${./emudhra.crt}" -CAkey "${./emudhra.crt}" -out server.crt -days 30 -sha256 -extfile ${extfile}

        cp server.key out/key.pem
        cat server.crt ${./emudhra.crt} > out/fullchain.pem
        chmod -u=rw,g=r,o= out/key.pem out/fullchain.pem
      '';

      unitConfig = {
        StartLimitIntervalSec = 0;
      };

      serviceConfig = {
        Group = config.services.nginx.group;
        UMask = "0027";

        RemainAfterExit = true;

        StateDirectory = "acme/gh-mitm.internal";

        BindPaths = [
          "/var/lib/acme/gh-mitm.internal:/tmp/out"
        ];

        # Same options as the nixpkgs acme module
        Type = "oneshot";
        User = "acme";
        StateDirectoryMode = "750";
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/var/lib/acme"
        ];
        PrivateTmp = true;

        WorkingDirectory = "/tmp";

        CapabilityBoundingSet = [ "" ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          # 1. allow a reasonable set of syscalls
          "@system-service @resources"
          # 2. and deny unreasonable ones
          "~@privileged"
          # 3. then allow the required subset within denied groups
          "@chown"
        ];
      };
    };
}
