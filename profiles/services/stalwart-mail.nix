# Stalwart mail server configuration
{
  inputs,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/stalwart-mail";
  managementPort = 9988;

  domain = "mail.acme-bnss.pt"; # TODO: change this to mail.diogotc.com after testing
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
      # Since system.stateVersion is lower than 24.11, we have to set some fields to use RocksDB instead of SQLite.
      store.db.type = "rocksdb";
      store.db.path = "${dataDir}/db";
      storage.blob = "db";

      server.listener = {
        smtp = {
          bind = ["[::]:25"];
          protocol = "smtp";
        };
        submission = {
          bind = ["[::]:587"];
          protocol = "smtp";
        };
        # submmissions = {
        # bind = ["[::]:465"];
        # protocol = "smtp";
        # tls.implicit = true;
        # };
        management = {
          bind = ["127.0.0.1:${toString managementPort}"];
          protocol = "http";
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
    587 # SMTP Submission
    465 # SMTP Submission Secure
  ];

  systemd.services.stalwart-mail.preStart = ''
    mkdir -p ${dataDir}/db
  '';

  services.caddy.virtualHosts.${domain} = {
    extraConfig = ''
      reverse_proxy localhost:${toString managementPort}
    '';
  };

  modules.impermanence.directories = [dataDir];
  modules.services.restic.paths = [dataDir];
}
