# Configuration for wireguard clients to well-known wireguard servers
{
  config,
  lib,
  secrets,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.services.wireguard-client;
in {
  options.modules.services.wireguard-client = {
    hera = {
      enable = mkEnableOption "wireguard client to hera's wireguard server";
      privateKey = mkOption {
        # Required
        type = types.str;
        description = "Wireguard Private key. Generate with `nix run pkgs#wireguard-tools genkey > private.key`";
      };
      lastOctect = mkOption {
        # Required
        type = types.ints.between 1 254;
        example = 2;
        description = "The last octect of the peer's IP address";
      };
    };
  };

  config = {
    age.secrets = {
      wireguardClientHeraPrivateKey = mkIf cfg.hera.enable {
        file = secrets.host.wireguardClientHeraPrivateKey;
      };
    };

    networking.wg-quick.interfaces = {
      hera = mkIf cfg.hera.enable {
        autostart = false;
        address = ["192.168.101.${toString cfg.hera.lastOctect}/24"];
        privateKeyFile = config.age.secrets.wireguardClientHeraPrivateKey.path;

        peers = [
          {
            publicKey = "XM/VFX/CWunMSiJX0tcv7F/ShDHPlP4RCySvbPkqHHQ=";
            allowedIPs = ["0.0.0.0/0" "::/0"];
            endpoint = "wireguard.hera.diogotc.com:51820";
          }
        ];
      };
    };
  };
}
