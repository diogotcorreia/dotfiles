# Stalwart mail server configuration
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  dataDir = "/var/lib/stalwart";
  httpPort = lib.my.ports.stalwartMailHttp;

  domain = "diogotc.com";
  robotsDomain = "robots.${domain}"; # emails from services come from this subdomain
  stalwartDomain = "mail.${domain}";
  roundcubeDomain = "webmail.${domain}";
  mailDomains = [
    domain
  ];

  mkEmail = name: "${name}@${domain}";

  credPath = "/run/credentials/stalwart.service";

  # Use the same version of rocksdb for backups
  rocksdb = config.services.stalwart.package.rocksdb;

  # utils for config
  ifthen = field: data: {
    "if" = field;
    "then" = data;
  };
  otherwise = value: { "else" = value; };
in
{
  age.secrets.smtp2goPassword.file = secrets.host.smtp2goPassword;

  services.stalwart = {
    enable = true;
    stateVersion = "26.05";
    settings = {
      config.local-keys = [
        "authentication.fallback-admin.*"
        "certificate.*"
        "cluster.node-id"
        "directory.*"
        "lookup.default.domain"
        "lookup.default.hostname"
        "metrics.*"
        "queue.route.*"
        "queue.strategy.route.*"
        "report.analysis.*"
        "resolver.*"
        "server.*"
        "!server.blocked-ip.*"
        "session.mta-sts.*"
        "session.rcpt.catch-all"
        "session.rcpt.rewrite.*"
        "spam-filter.resource"
        "storage.blob"
        "storage.data"
        "storage.directory"
        "storage.fts"
        "storage.lookup"
        "store.*"
        "tracer.*"
        "webadmin.*"
      ];

      # Store blobs in the file system for easier backups.
      # Since the database is backed up to /tmp, it would not fit in RAM
      # with all the blobs.
      store.fs = {
        type = "fs";
        path = "${dataDir}/blobs";
      };
      storage.blob = "fs";

      session.rcpt = {
        rewrite = [
          (ifthen "rcpt_domain == '${robotsDomain}'" "'${mkEmail "robots"}'")
          (otherwise false)
        ];
        # Enable catch-all addresses
        catch-all = true;
      };

      # We have DANE and don't want to have a certificate for each domain we serve.
      session.mta-sts.mode = "none";

      report.analysis = {
        # https://github.com/stalwartlabs/mail-server/discussions/877
        addresses = [
          "dmarc-reports@*"
          "spf-reports@*"
          "tls-reports@*"
        ];
        forward = false;
      };

      server.listener = {
        smtp = {
          bind = [ "[::]:${toString lib.my.ports.smtp}" ];
          protocol = "smtp";
        };
        submission = {
          bind = [ "[::]:${toString lib.my.ports.emailSubmission}" ];
          protocol = "smtp";
        };
        submissions = {
          bind = [ "[::]:${toString lib.my.ports.emailSubmissionTls}" ];
          protocol = "smtp";
          tls.implicit = true;
        };
        imap = {
          bind = [ "[::]:${toString lib.my.ports.imap}" ];
          protocol = "imap";
        };
        imaps = {
          bind = [ "[::]:${toString lib.my.ports.imaps}" ];
          protocol = "imap";
          tls.implicit = true;
        };
        sieve = {
          bind = [ "[::]:${toString lib.my.ports.manageSieve}" ];
          protocol = "managesieve";
          tls.implicit = true;
        };
        http = {
          bind = [ "[::]:${toString httpPort}" ];
          protocol = "http";
          url = "https://${stalwartDomain}";
          use-x-forwarded = true;
        };
      };

      certificate.default = {
        cert = "%{file:${credPath}/cert.pem}%";
        private-key = "%{file:${credPath}/key.pem}%";
        default = true;
      };
      lookup = {
        default = {
          inherit domain;
          hostname = stalwartDomain;
        };
      };

      tracer = {
        log = {
          enable = true;
          type = "log";
          path = "%{env:LOGS_DIRECTORY}%";
          prefix = "stalwart.log";
          level = "info";
        };
      };

      metrics.prometheus.enable = true;
      # not really a setting for stalwart, just for prometheus
      metrics.prometheus.host = "metrics.${stalwartDomain}";

      # Just for initial setup - comment immediately!
      # authentication.fallback-admin = {
      # user = "admin";
      # secret = "changemeasap";
      # };

      # Routing with SMTP2GO configuration
      queue = {
        route = {
          smtp2go = {
            type = "relay";
            address = "mail-eu.smtp2go.com";
            protocol = "smtp";
            port = 8465;
            tls.implicit = true;
            auth = {
              username = "diogotc.com";
              secret = "%{file:${credPath}/smtp2goPassword}%";
            };
          };

          local.type = "local";

          mx = {
            type = "mx";
            ip-lookup = "ipv4_then_ipv6";
            limits = {
              mx = 5;
              multihomed = 2;
            };
          };
        };

        strategy.route = [
          (ifthen "is_local_domain('', rcpt_domain)" "'local'")
          # sometimes spf reports are sent to mail.<domain> instead, which is not registered as a local domain
          (ifthen "rcpt_domain == 'mail.${domain}'" "'local'")
          # use SMTP2GO only for diogotc.com
          (ifthen "sender_domain == '${domain}'" "'smtp2go'")
          (otherwise "'mx'")
        ];
      };
    };

    credentials = {
      "cert.pem" = "${config.security.acme.certs.${stalwartDomain}.directory}/cert.pem";
      "key.pem" = "${config.security.acme.certs.${stalwartDomain}.directory}/key.pem";
      smtp2goPassword = config.age.secrets.smtp2goPassword.path;
    };
  };

  networking.firewall.allowedTCPPorts = with lib.my.ports; [
    smtp
    imap
    emailSubmissionTls
    emailSubmission
    imaps
    manageSieve
  ];

  systemd.services.stalwart = {
    wants = [ "acme-${stalwartDomain}.service" ];
    after = [ "acme-${stalwartDomain}.service" ];
    serviceConfig = {
      LogsDirectory = "stalwart";
    };
  };

  services.roundcube = {
    enable = true;
    package = pkgs.roundcube;
    dicts = with pkgs.aspellDicts; [
      en
      pt_PT
      sv
    ];
    hostName = roundcubeDomain;
    plugins = [
      "archive"
      "zipdownload"
      "managesieve"
      "acl"
    ];
    extraConfig = ''
      $config['imap_host'] = 'ssl://${stalwartDomain}:993';
      $config['smtp_host'] = 'ssl://%h:465';
      $config['managesieve_host'] = 'ssl://%h';
      $config['mail_domain'] = '%z';
    '';
  };

  services.nginx.virtualHosts =
    let
      proxy = "http://localhost:${toString httpPort}";
    in
    {
      ${stalwartDomain} = {
        enableACME = true;
        locations."/".proxyPass = proxy;
        locations."/metrics/prometheus".extraConfig = ''
          deny all;
        '';
      };
      "metrics.${stalwartDomain}" = {
        enableACME = true;
        locations."/metrics/prometheus" = {
          proxyPass = proxy;
          # only allow connections from phobos
          extraConfig = ''
            allow 192.168.100.7;
            deny all;
          '';
        };
      };
    }
    // lib.listToAttrs (
      map (
        d:
        lib.nameValuePair "autoconfig.${d}" {
          serverAliases = [
            "autodiscovery.${d}"
          ];
          enableACME = true;
          locations = {
            "= /mail/config-v1.1.xml".proxyPass = proxy;
            "= /autodiscovery/autodiscovery.xml".proxyPass = proxy;
            "/.well-known".proxyPass = proxy;
          };
        }
      ) mailDomains
    );

  security.acme.certs.${stalwartDomain} = {
    # keep a stable private key for TLSA records (DANE)
    # https://community.letsencrypt.org/t/please-avoid-3-0-1-and-3-0-2-dane-tlsa-records-with-le-certificates/7022/14
    extraLegoRenewFlags = [ "--reuse-key" ];
    # Restart stalwart to apply new certificates
    reloadServices = [ "stalwart.service" ];
  };

  modules.impermanence.directories = [ dataDir ];
  modules.services.restic = {
    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 700 -d /tmp/stalwart-db-secondary /tmp/stalwart-db-backup
      ${lib.getExe' rocksdb.tools "ldb"} --db=${dataDir}/db --secondary_path=/tmp/stalwart-db-secondary backup --backup_dir=/tmp/stalwart-db-backup
    '';
    backupCleanupCommand = ''
      rm -rf /tmp/stalwart-db-secondary
      rm -rf /tmp/stalwart-db-backup
    '';
    paths = [
      "/tmp/stalwart-db-backup"
      "${dataDir}/blobs"
    ];
  };
}
