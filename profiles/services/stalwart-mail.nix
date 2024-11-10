# Stalwart mail server configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/stalwart-mail";
  httpPort = 9988;

  domain = "acme-bnss.pt"; # TODO: change this to diogotc.com after testing
  stalwartDomain = "mail.${domain}";
  mailDomains = [
    "acme-bnss.pt"
  ];

  credPath = "/run/credentials/stalwart-mail.service";

  # Use the same version of rocksdb for backups
  rocksdb = config.services.stalwart-mail.package.rocksdb;
in {
  # Use stalwart module from unstable
  # TODO: remove on nixos-24.11
  disabledModules = [
    "services/mail/stalwart-mail.nix"
  ];
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/mail/stalwart-mail.nix")
  ];

  services.stalwart-mail = {
    enable = true;
    package = pkgs.unstable.stalwart-mail;
    settings = {
      config.local-keys = [
        "authentication.fallback-admin.*"
        "certificate.*"
        "cluster.node-id"
        "directory.*"
        "lookup.default.domain"
        "lookup.default.hostname"
        "report.analysis.*"
        "server.*"
        "!server.blocked-ip.*"
        "session.rcpt.catch-all"
        "storage.blob"
        "storage.data"
        "storage.directory"
        "storage.fts"
        "storage.lookup"
        "store.*"
        "tracer.*"
      ];

      # Since system.stateVersion is lower than 24.11, we have to set some fields to use RocksDB instead of SQLite.
      store.db.type = "rocksdb";
      store.db.path = "${dataDir}/db";
      storage.blob = "db";

      session.rcpt = {
        # Enable catch-all addresses
        catch-all = true;
      };

      report.analysis = {
        # https://github.com/stalwartlabs/mail-server/discussions/877
        addresses = ["dmarc-reports@*" "spf-reports@*"];
        forward = false;
      };

      server.listener = {
        smtp = {
          bind = ["[::]:25"];
          protocol = "smtp";
        };
        submission = {
          bind = ["[::]:587"];
          protocol = "smtp";
        };
        submmissions = {
          bind = ["[::]:465"];
          protocol = "smtp";
          tls.implicit = true;
        };
        imap = {
          bind = ["[::]:143"];
          protocol = "imap";
        };
        imaps = {
          bind = ["[::]:993"];
          protocol = "imap";
          tls.implicit = true;
        };
        http = {
          bind = ["[::]:${toString httpPort}"];
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
          prefix = "stalwart-mail.log";
          level = "info";
        };
      };

      # Just for initial setup - comment immediately!
      # authentication.fallback-admin = {
      # user = "admin";
      # secret = "changemeasap";
      # };
    };
  };

  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    143 # IMAP
    465 # SMTP Submission Secure
    587 # SMTP Submission
    993 # IMAP Secure
  ];

  systemd.services.stalwart-mail = {
    wants = ["acme-${stalwartDomain}.service"];
    after = ["acme-${stalwartDomain}.service"];
    preStart = ''
      mkdir -p ${dataDir}/db
    '';
    serviceConfig = {
      LogsDirectory = "stalwart-mail";
      LoadCredential = [
        "cert.pem:${config.security.acme.certs.${stalwartDomain}.directory}/cert.pem"
        "key.pem:${config.security.acme.certs.${stalwartDomain}.directory}/key.pem"
      ];
    };
  };

  services.caddy.virtualHosts =
    {
      ${stalwartDomain} = {
        enableACME = true;
        extraConfig = ''
          reverse_proxy localhost:${toString httpPort}
        '';
      };
    }
    // lib.listToAttrs (
      map (
        d:
          lib.nameValuePair
          "mta-sts.${d}"
          {
            serverAliases = [
              "autoconfig.${d}"
              "autodiscovery.${d}"
            ];
            enableACME = true;
            extraConfig = ''
              @discovery path /mail/config-v1.1.xml /autodiscovery/autodiscovery.xml /.well-known/*
              handle @discovery {
                reverse_proxy localhost:${toString httpPort}
              }
              handle {
                respond 404
              }
            '';
          }
      )
      mailDomains
    );

  modules.impermanence.directories = [dataDir];
  modules.services.restic = {
    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 700 -d /tmp/stalwart-db-secondary /tmp/stalwart-db-backup
      ${lib.getExe' rocksdb.tools "ldb"} --db=${dataDir}/db --secondary_path=/tmp/stalwart-db-secondary backup --backup_dir=/tmp/stalwart-db-backup
    '';
    backupCleanupCommand = ''
      rm -rf /tmp/stalwart-db-secondary
      rm -rf /tmp/stalwart-db-backup
    '';
    paths = ["/tmp/stalwart-db-backup"];
  };
}
