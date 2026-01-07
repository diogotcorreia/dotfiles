# Collect settings from all hosts so that the authelia instance
# configures itself automatically.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my.services.authelia = {
    ldapExtraAttributes = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            freeformType = types.attrsOf types.anything;
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                description = ''
                  The name of the claim in Authelia.
                '';
              };
              value_type = mkOption {
                type = types.enum [
                  "string"
                  "integer"
                  "boolean"
                ];
                example = "string";
                description = ''
                  Required. Type of this attribute.
                '';
              };
              multi_valued = mkOption {
                type = types.bool;
                default = false;
                description = ''
                  Whether this attribute can have more than a single value.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Extra LDAP attributes to import into Authelia claims.
      '';
    };
    accessRules = mkOption {
      type = types.listOf (
        types.submodule (
          { ... }:
          {
            options = {
              domain = mkOption {
                type = types.either types.str (types.listOf types.str);
                default = [ ];
                example = [ "subdomain.example.com" ];
                description = ''
                  The domains this rule applies to.
                  This can be applied alongside `domain_regex`.
                '';
              };
              domain_regex = mkOption {
                type = types.either types.str (types.listOf types.str);
                default = [ ];
                example = [ "^(data|img)\.example\.com$" ];
                description = ''
                  The regex representing the domains this rule applies to.
                  This can be applied alongside `domain`.
                '';
              };
              policy = mkOption {
                type = types.enum [
                  "deny"
                  "bypass"
                  "one_factor"
                  "two_factor"
                ];
                default = "two_factor";
                description = ''
                  The policy (action to take) to apply to the rule.
                '';
              };
              subject = mkOption {
                type = types.either types.str (types.listOf (types.either types.str (types.listOf types.str)));
                default = [ ];
                example = [
                  "user:json"
                  [
                    "group:admin"
                    "group:app-name"
                  ]
                  "group:super-admin"
                ];
                description = ''
                  Match characteristics of the subject trying to access the page.
                  Prefix with `user:`, `group:` or `oauth2:client:`.
                  The first level list is OR'ed together, while the second level
                  list is AND'ed together.
                '';
              };
              methods = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "OPTIONS" ];
                description = ''
                  Match the HTTP request method.
                '';
              };
              networks = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [
                  "10.0.0.0/8"
                  "172.16.0.0/12"
                ];
                description = ''
                  Match the IP address of the user trying to access the page,
                  in CIDR notation.
                '';
              };
              resources = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "^/api([/?].*)?$" ];
                description = ''
                  Match the path and query of the request using regular expressions.
                '';
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        Access control rules to add to authelia.
        By default, everything is blocked and access has to be explicitly granted.
      '';
    };
    oauthClients = mkOption {
      type = types.listOf (
        types.submodule (
          { ... }:
          {
            freeformType = types.attrsOf types.anything;
            options = {
              client_id = mkOption {
                type = types.str;
                example = "gouio42igdglsajg21i";
                description = ''
                  Required. The client ID of this OAuth client.
                '';
              };
              client_name = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "MyApp";
                description = ''
                  A user-friendly name for this client, show in the UI.
                '';
              };
              client_secret = mkOption {
                type = types.str;
                example = "$pbkdf2-sha512$...";
                description = ''
                  Required. The hash of the client secret of this OAuth client.
                '';
              };
              redirect_uris = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [ "https://example.com/oauth/callback" ];
                description = ''
                  A list of valid callback URIs this client will redirect to.
                  All other callbacks will be considered unsafe.
                  Case-sensitive.
                '';
              };
              scopes = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [
                  "openid"
                  "groups"
                  "profile"
                  "email"
                ];
                description = ''
                  A list of scopes to allow this client to consume.
                '';
              };
              policy = mkOption {
                type = types.enum [
                  "deny"
                  "bypass"
                  "one_factor"
                  "two_factor"
                ];
                default = "two_factor";
                description = ''
                  The policy (action to take) to apply to this client.
                '';
              };
              subject = mkOption {
                type = types.either types.str (types.listOf (types.either types.str (types.listOf types.str)));
                default = [ ];
                example = [
                  "user:json"
                  [
                    "group:admin"
                    "group:app-name"
                  ]
                  "group:super-admin"
                ];
                description = ''
                  Match characteristics of the subject trying to access the client.
                  Prefix with `user:`, `group:` or `oauth2:client:`.
                  The first level list is OR'ed together, while the second level
                  list is AND'ed together.
                '';
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        OAuth Clients to add to authelia.
      '';
    };
    oidcScopes = mkOption {
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            freeformType = types.attrsOf types.anything;
            options = {
              claims = mkOption {
                type = types.listOf types.str;
                example = [ "custom_claim" ];
                description = ''
                  Required. The claims included in this scope.
                '';
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Extra OIDC claims to create.
      '';
    };
  };
}
