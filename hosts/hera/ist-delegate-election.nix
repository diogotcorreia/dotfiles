# hosts/hera/ist-delegate-election.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for IST Delegate Election on Hera
{
  pkgs,
  config,
  hostSecretsDir,
  ...
}: let
  domain = "ist-delegate-election.diogotc.com";
  port = 8385;

  dbUser = config.services.ist-delegate-election.user;
in {
  age.secrets.heraIstDelegateElectionFenixSecret = {
    file = "${hostSecretsDir}/istDelegateElectionFenixSecret.age";
    owner = config.services.ist-delegate-election.user;
    group = config.services.ist-delegate-election.group;
  };

  services.ist-delegate-election = {
    inherit port;
    enable = true;

    fqdn = "https://${domain}";

    settings = {
      FENIX_BASE_URL = "https://fenix.tecnico.ulisboa.pt";
      FENIX_CLIENT_ID = "3103289965019140";

      DATABASE_URL = "postgres:///${dbUser}";
    };

    settingsFile = config.age.secrets.heraIstDelegateElectionFenixSecret.path;
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [dbUser];
  };

  security.acme.certs.${domain} = {};

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
      '';
    };
  };
}
