{...}: let
  domain = "grafana.diogotc.com";
  port = 8032;

  dbUser = "grafana";
in {
  services.postgresql = {
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [dbUser];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://${domain}";
        http_port = port;
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        name = dbUser;
        user = dbUser;
      };

      security = {
        # admin_password = "$__env{GRAFANA_SECURITY_ADMIN_PASSWORD}";
        cookie_secure = true;
        cookie_samesite = "strict";
        allow_embedding = true;
      };

      analytics = {
        reporting_enabled = false;
        feedback_enabled = false;
      };
    };
  };

  services.caddy.virtualHosts.${domain} = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };
}
