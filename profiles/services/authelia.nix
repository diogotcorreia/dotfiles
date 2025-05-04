# Authelia OAuth2 & OIDC
{
  config,
  lib,
  nixosConfigurations,
  secrets,
  ...
}: let
  redisCfg = config.services.redis.servers.authelia;
  cfg = config.services.authelia.instances.dtc;

  baseDomain = "diogotc.com";
  domain = "auth.${baseDomain}";
  port = lib.my.ports.authelia;

  dbUser = cfg.user;

  accessControlRules = lib.pipe nixosConfigurations [
    builtins.attrValues
    (map (cfg: cfg.config.my.services.authelia.accessRules))
    builtins.concatLists
  ];

  oidcClients = lib.pipe nixosConfigurations [
    builtins.attrValues
    (map (cfg: cfg.config.my.services.authelia.oauthClients))
    builtins.concatLists
  ];
  hasOidcClients = oidcClients != [];
in {
  # https://www.authelia.com/reference/guides/generating-secure-values/
  age.secrets = builtins.listToAttrs (map (name:
    lib.nameValuePair name {
      inherit (cfg) group;
      owner = cfg.user;
      file = secrets.host.${name};
    }) [
    "autheliaJwtSecret"
    "autheliaLdapPassword"
    "autheliaOidcHmacSecret"
    "autheliaOidcIssuerPrivateKey"
    "autheliaSessionSecret"
    "autheliaSmtpPassword"
    "autheliaStorageEncryptionKey"
  ]);

  services.authelia.instances.dtc = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets.autheliaJwtSecret.path;
      # if there are no clients and this is set, authelia will not turn on
      oidcHmacSecretFile = lib.mkIf hasOidcClients config.age.secrets.autheliaOidcHmacSecret.path;
      oidcIssuerPrivateKeyFile = lib.mkIf hasOidcClients config.age.secrets.autheliaOidcIssuerPrivateKey.path;
      sessionSecretFile = config.age.secrets.autheliaSessionSecret.path;
      storageEncryptionKeyFile = config.age.secrets.autheliaStorageEncryptionKey.path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.autheliaLdapPassword.path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.age.secrets.autheliaSmtpPassword.path;
    };
    settings = {
      theme = "auto";
      default_2fa_method = "totp";
      log.level = "info";

      server = {
        address = "tcp://:${toString port}/";
        disable_healthcheck = true;
      };

      authentication_backend = {
        ldap = let
          baseDn = "dc=diogotc,dc=com";
        in {
          implementation = "lldap";
          address = "ldap://[::1]:${toString config.services.lldap.settings.ldap_port}";
          base_dn = baseDn;

          user = "uid=authelia,ou=people,${baseDn}";
          # password is passed as env variable
        };
      };

      access_control = {
        default_policy = "deny";
        rules =
          [
            {
              domain = [domain];
              policy = "bypass";
            }
          ]
          ++ accessControlRules;
      };

      session = {
        expiration = "12h";
        inactivity = "45m";
        remember_me = "1M";
        cookies = [
          {
            domain = baseDomain;
            authelia_url = "https://${domain}";
          }
        ];
        redis.host = redisCfg.unixSocket;
      };

      storage = {
        postgres = {
          address = "unix:///run/postgresql";
          database = dbUser;
          username = dbUser;
          # required by authelia but not used; using peer auth
          # see https://github.com/authelia/authelia/pull/8161
          password = dbUser;
        };
      };

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submissions://mail.diogotc.com:465";
          username = lib.my.mkRobotsEmail "authelia";
          # password through env variables
          sender = "Authelia <${lib.my.mkRobotsEmail "authelia"}>";
        };
      };

      duo_api.disable = true;
      totp = {
        disable = false;
        issuer = domain;
      };
      webauthn = {
        disable = false;
        display_name = domain;
      };

      identity_providers = lib.mkIf hasOidcClients {
        oidc = let
          # policy name can't contain dots or tildes and needs to be lowercase
          # https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
          mkPolicyName = client_id: "policy_${lib.toLower (lib.replaceStrings ["." "~"] ["_" "_"] client_id)}";
          customAuthorizationPolicies = lib.pipe oidcClients [
            (lib.filter (client: client.subject != []))
            (map (client:
              lib.nameValuePair (mkPolicyName client.client_id) {
                default_policy = "deny";
                rules = [
                  {
                    policy = client.policy;
                    subject = client.subject;
                  }
                ];
              }))
            lib.listToAttrs
          ];
          clients =
            map (client: {
              inherit (client) client_id client_name client_secret redirect_uris;
              scopes = lib.mkIf (client.scopes != []) client.scopes;
              authorization_policy =
                if client.subject == []
                then client.policy
                else mkPolicyName client.client_id;
              # save consent for 1 year
              pre_configured_consent_duration = "1y";
            })
            oidcClients;
        in {
          authorization_policies = lib.mkIf (customAuthorizationPolicies != {}) customAuthorizationPolicies;
          inherit clients;
        };
      };
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      locations."/".proxyPass = "http://[::1]:${toString port}";
    };
  };

  # allow other servers to connect
  modules.services.nebula.firewall.inbound = let
    hostsWithAccessRules = lib.attrNames (
      lib.filterAttrs (_: {config, ...}: config.my.services.authelia.accessRules != []) nixosConfigurations
    );
  in
    map (host: {
      port = port;
      proto = "tcp";
      inherit host;
    })
    hostsWithAccessRules;

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

  # use redis to persist sessions across reboots
  services.redis.servers = {
    authelia = {
      enable = true;
    };
  };

  # give authelia perms to access redis socket
  users.users."authelia-${cfg.name}".extraGroups = [redisCfg.group];

  # persist redis directory across reboots
  modules.impermanence.directories = ["/var/lib/redis-authelia"];
}
