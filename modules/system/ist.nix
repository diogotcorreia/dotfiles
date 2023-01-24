# modules/system/ist.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for services and programs needed while studying
# at Técnico Lisboa (IST).

{ pkgs, config, lib, utils, user, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.ist;
in {
  options.modules.ist.enable = mkEnableOption "ist";

  config = mkIf cfg.enable {
    krb5 = {
      enable = true;
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
        "IST.UTL.PT" = { admin_server = "kerberosmaster.ist.utl.pt"; };
      };
    };
  };
}
