# Extra options for the nixpkgs caddy module
{
  config,
  lib,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mkIf mkOption types;

  cfg = config.services.caddy;

  acmeEnabledVhosts = filterAttrs (_: vhostConfig: vhostConfig.enableACME) cfg.virtualHosts;
in {
  options.services.caddy = {
    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule (
        {
          name,
          config,
          ...
        }: {
          options = {
            # Heavily inspired by the nginx module's option of the same name
            enableACME = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to ask Let's Encrypt to sign a certificate for this vhost.
                Alternately, you can use an existing certificate through {option}`useACMEHost`.
              '';
            };
          };

          # Leverage existing useACMEHost option
          config = mkIf (config.enableACME) {
            useACMEHost = name;
          };
        }
      ));
    };
  };

  config = mkIf cfg.enable {
    security.acme.certs =
      mapAttrs (_: vhostConfig: {
        domain = vhostConfig.hostName;
        extraDomainNames = vhostConfig.serverAliases;
      })
      acmeEnabledVhosts;
  };
}
