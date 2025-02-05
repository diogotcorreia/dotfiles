# Collect settings from all hosts so that the authelia instance
# configures itself automatically.
{
  config,
  lib,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mkIf mkOption types;
in {
  options.my.services.authelia = {
    accessRules = mkOption {
      type = types.listOf (types.submodule (
        {
          name,
          config,
          ...
        }: {
          options = {
            domain = mkOption {
              type = types.either types.str (types.listOf types.str);
              default = [];
              example = ["subdomain.example.com"];
              description = ''
                The domains this rule applies to.
                This can be applied alongside `domain_regex`.
              '';
            };
            domain_regex = mkOption {
              type = types.either types.str (types.listOf types.str);
              default = [];
              example = ["^(data|img)\.example\.com$"];
              description = ''
                The regex representing the domains this rule applies to.
                This can be applied alongside `domain`.
              '';
            };
            policy = mkOption {
              type = types.enum ["deny" "bypass" "one_factor" "two_factor"];
              default = "two_factor";
              description = ''
                The policy (action to take) to apply to the rule.
              '';
            };
            subject = mkOption {
              type = types.either types.str (types.listOf (
                types.either types.str (types.listOf types.str)
              ));
              default = [];
              example = ["user:json" ["group:admin" "group:app-name"] "group:super-admin"];
              description = ''
                Match characteristics of the subject trying to access the page.
                Prefix with `user:`, `group:` or `oauth2:client:`.
                The first level list is OR'ed together, while the second level
                list is AND'ed together.
              '';
            };
            methods = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["OPTIONS"];
              description = ''
                Match the HTTP request method.
              '';
            };
            networks = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["10.0.0.0/8" "172.16.0.0/12"];
              description = ''
                Match the IP address of the user trying to access the page,
                in CIDR notation.
              '';
            };
            resources = mkOption {
              type = types.listOf types.str;
              default = [];
              example = ["^/api([/?].*)?$"];
              description = ''
                Match the path and query of the request using regular expressions.
              '';
            };
          };
        }
      ));
      default = [];
      description = ''
        Access control rules to add to authelia.
        By default, everything is blocked and access has to be explicitly granted.
      '';
    };
  };
}
