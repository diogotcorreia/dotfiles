# LDAP server
{
  config,
  lib,
  secrets,
  ...
}: let
  domain = "ldap.diogotc.com";
  port = lib.my.ports.lldapHttp;

  dbUser = "lldap";
in {
  age.secrets.lldapEnv.file = secrets.host.lldapEnv;

  services.lldap = {
    enable = true;
    # Contains:
    # - LLDAP_JWT_SECRET
    # - LLDAP_KEY_SEED
    environmentFile = config.age.secrets.lldapEnv.path;
    settings = {
      ldap_user_dn = "dtc";
      ldap_user_pass = "pleaseChangeMeAfterFirstLogin";
      force_ldap_user_pass_reset = false; # otherwise the admin user will always have the password above ;/

      ldap_base_dn = "dc=diogotc,dc=com";
      ldap_host = "::1";
      ldap_port = lib.my.ports.lldapLdap;

      http_url = "https://${domain}";
      http_host = "::1";
      http_port = port;

      database_url = "postgres:///${dbUser}?host=/run/postgresql";
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
    ensureDatabases = [dbUser];
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };
}
