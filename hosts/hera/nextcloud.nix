# hosts/hera/nextcloud.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Nextcloud on Hera

{ pkgs, config, ... }:
let
  domain = "cloud.diogotc.com";
  port = 8007;
in {

  # TODO move docker containers to NixOS services

  security.acme.certs.${domain} = { };

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        encode zstd gzip
        redir /.well-known/carddav /remote.php/carddav 301
        redir /.well-known/caldav /remote.php/caldav 301
        reverse_proxy localhost:${toString port} {
          import CLOUDFLARE_PROXY
          header_down Strict-Transport-Security "max-age=15768000;"
        }

        request_body {
          max_size 2GB
        }
      '';
    };
  };

  modules.services.restic = {
    paths = [ "/tmp/nextcloud_db.sql" "${config.my.homeDirectory}/nextcloud" ];
    backupPrepareCommand = ''
      ${pkgs.coreutils}/bin/install -b -m 600 /dev/null /tmp/nextcloud_db.sql
      ${pkgs.docker}/bin/docker compose -f ${config.my.homeDirectory}/nextcloud/docker-compose.yml exec -T db sh -c 'exec mysqldump --host=db --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE' > /tmp/nextcloud_db.sql
    '';
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm /tmp/nextcloud_db.sql
    '';

  };
}
