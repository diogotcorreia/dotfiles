# Configuration for services and programs needed while studying
# at Técnico Lisboa (IST).
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf escapeShellArg getAttr attrNames;
  cfg = config.modules.ist;
in {
  options.modules.ist.enable = mkEnableOption "ist";

  config = mkIf cfg.enable {
    # Kerberos authentication
    security.krb5 = {
      enable = true;
      settings = {
        libdefaults = {
          default_realm = "IST.UTL.PT";
          kdc_timesync = 1;
          ccache_type = 4;
          forwardable = true;
          proxiable = true;
        };
        domain_realm = {
          "ist.utl.pt" = "IST.UTL.PT";
          ".ist.utl.pt" = "IST.UTL.PT";
        };
        realms = {
          "IST.UTL.PT" = {admin_server = "kerberosmaster.ist.utl.pt";};
        };
      };
    };
    # By default, the kerberos pam module is enabled when kerberos is enabled, which we don't want
    security.pam.krb5.enable = false;
  };
}
