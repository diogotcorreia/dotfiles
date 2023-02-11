# modules/ist.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for services and programs needed while studying
# at Técnico Lisboa (IST).

{ pkgs, config, lib, utils, user, secretsDir, ... }:
let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.ist;

  istVpnConfiguration = pkgs.fetchurl {
    url =
      "https://suporte.dsi.tecnico.ulisboa.pt/sites/default/files/files/tecnico.ovpn";
    sha256 = "sha256-3vQ5eyrB2IEKHJXXDJk3kPXRbNwGsRpcN8hmPl7ihBQ=";
  };
in {
  options.modules.ist.enable = mkEnableOption "ist";

  config = mkIf cfg.enable {
    # Kerberos authentication
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

    # OpenVPN
    age.secrets.openvpnIstAuthUserPass.file =
      "${secretsDir}/openvpnIstAuthUserPass.age";
    services.openvpn.servers.ist = {
      autoStart = false;
      config = ''
        config ${istVpnConfiguration}
        auth-user-pass ${config.age.secrets.openvpnIstAuthUserPass.path}
      '';
    };
  };
}
