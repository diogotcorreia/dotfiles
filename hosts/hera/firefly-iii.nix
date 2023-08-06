# hosts/hera/firefly-iii.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Firefly-III on Hera

{ pkgs, config, ... }:
let
  domainApp = "firefly3.hera.diogotc.com";
  portApp = 8005;
  domainDataImporter = "firefly3-csv.hera.diogotc.com";
  portDataImporter = 8006;
in {

  # TODO move docker containers to NixOS services
  # TODO Importer cron job

  security.acme.certs = {
    ${domainApp} = { };
    ${domainDataImporter} = { };
  };

  services.caddy.virtualHosts = {
    ${domainApp} = {
      useACMEHost = domainApp;
      extraConfig = ''
        import NEBULA
        reverse_proxy localhost:${toString portApp}
      '';
    };
    ${domainDataImporter} = {
      useACMEHost = domainDataImporter;
      extraConfig = ''
        import NEBULA
        reverse_proxy localhost:${toString portDataImporter}
      '';
    };
  };

  modules.services.restic = {
    paths = [ "/tmp/firefly_db.sql" "${config.my.homeDirectory}/firefly-3" ];

    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/firefly_db.sql
      ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/firefly-3/docker-compose.yml exec -T fireflyiiidb sh -c 'exec mysqldump --host=fireflyiiidb --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE' > /tmp/firefly_db.sql
    '';
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm /tmp/firefly_db.sql
    '';
  };
}
