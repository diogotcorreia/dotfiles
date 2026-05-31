# LDAP server
{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "ldap.diogotc.com";
  port = lib.my.ports.lldapHttp;

  dbUser = "lldap";
in
{
  age.secrets.lldapAdminPassword.file = secrets.host.lldapAdminPassword;
  age.secrets.lldapEnv.file = secrets.host.lldapEnv;

  services.lldap = {
    enable = true;
    # Contains:
    # - LLDAP_JWT_SECRET
    # - LLDAP_KEY_SEED
    environmentFile = config.age.secrets.lldapEnv.path;
    environment = {
      LLDAP_LDAP_USER_PASS_FILE = "%d/user_pass";
    };
    settings = {
      ldap_user_dn = "superadmin";
      ldap_user_email = lib.my.mkDtcEmail "ldap.superadmin";
      force_ldap_user_pass_reset = "always";

      ldap_base_dn = "dc=diogotc,dc=com";
      ldap_host = "::1";
      ldap_port = lib.my.ports.lldapLdap;

      http_url = "https://${domain}";
      http_host = "::1";
      http_port = port;

      # TODO 26.05: use services.lldap.database
      database_url = "postgres:///${dbUser}?host=/run/postgresql";
    };
  };

  systemd.services.lldap = {
    # ensure postgresql is ready before turning on lldap
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];

    serviceConfig = {
      LoadCredential = [ "user_pass:${config.age.secrets.lldapAdminPassword.path}" ];
    };
  };

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [
      {
        name = dbUser;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ dbUser ];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };
}
