# Stalwart mail server configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/stalwart-mail";
  httpPort = lib.my.ports.stalwartMailHttp;

  domain = "diogotc.com";
  robotsDomain = "robots.${domain}"; # emails from services come from this subdomain
  stalwartDomain = "mail.${domain}";
  roundcubeDomain = "webmail.${domain}";
  mailDomains = [
    domain
  ];

  mkEmail = name: "${name}@${domain}";

  credPath = "/run/credentials/stalwart-mail.service";

  # Use the same version of rocksdb for backups
  rocksdb = config.services.stalwart-mail.package.rocksdb;

  # utils for config
  ifthen = field: data: {
    "if" = field;
    "then" = data;
  };
  otherwise = value: { "else" = value; };
in
{
  # Use module from nixos-unstable
  # TODO: move to stable on NixOS 25.11
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
        "session.mta-sts.*"
        "session.rcpt.rewrite"
        "session.rcpt.catch-all"
        "storage.blob"
        "storage.data"
        "storage.directory"
        "storage.fts"
        "storage.lookup"
        "store.*"
        "tracer.*"
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
        submmissions = {
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

  networking.firewall.allowedTCPPorts = with lib.my.ports; [
    smtp
    imap
    emailSubmissionTls
    emailSubmission
    imaps
    manageSieve
  ];

  systemd.services.stalwart-mail = {
    wants = [ "acme-${stalwartDomain}.service" ];
    after = [ "acme-${stalwartDomain}.service" ];
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
    reloadServices = [ "stalwart-mail.service" ];
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
