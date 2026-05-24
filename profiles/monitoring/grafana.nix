{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "grafana.diogotc.com";
  port = lib.my.ports.grafana;

  dbUser = "grafana";
in
{
  age.secrets.grafanaAdminPassword = {
    file = secrets.host.grafanaAdminPassword;
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://${domain}";
        http_addr = "::1";
        http_port = port;
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = dbUser;
        user = dbUser;
      };

      security = {
        admin_password = "$__file{${config.age.secrets.grafanaAdminPassword.path}}";
        cookie_secure = true;
        cookie_samesite = "strict";
        allow_embedding = true;

        # See https://nixos.org/manual/nixos/unstable/release-notes#sec-release-26.05-incompatibilities
        # TODO: In the future it might be reasonable to generate a new secret key
        secret_key = "SW2YcwTIb9zpOOhoPsMm";
      };

      analytics = {
        reporting_enabled = false;
        feedback_enabled = false;
      };

      # TODO: oauth
    };
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ dbUser ];
  };

  services.nginx.virtualHosts.${domain} = {
    enableACME = true;
    locations."/".proxyPass = "http://[::1]:${toString port}";
  };

  modules.impermanence.directories = [
    config.services.grafana.dataDir
  ];

  modules.services.restic = {
    paths = [ config.services.grafana.dataDir ];
    exclude = [ "${config.services.grafana.dataDir}/plugins" ];
  };
}
