# Configuration for wireguard clients to well-known wireguard servers
{
  config,
  lib,
  secrets,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.modules.services.wireguard-client;

  mkServerOptions = description: {
    enable = mkEnableOption description;
    privateKeySecret = mkOption {
      # Required
      type = types.path;
      default = secrets.host.wireguardClientPrivateKey;
      description = "Wireguard Private key. Generate with `nix run pkgs#wireguard-tools genkey > private.key`";
    };
    lastOctect = mkOption {
      # Required
      type = types.ints.between 1 254;
      example = 2;
      description = "The last octect of the peer's IP address";
    };
  };

  mkServerSecrets = serverCfg:
    mkIf serverCfg.enable {
      file = serverCfg.privateKeySecret;
    };
in {
  options.modules.services.wireguard-client = {
    feb-router = mkServerOptions "wireguard client to the router in feb's network";
    hera = mkServerOptions "wireguard client to hera's wireguard server";
  };

  config = {
    age.secrets = {
      wireguardClientFebRouterPrivateKey = mkServerSecrets cfg.feb-router;
      wireguardClientHeraPrivateKey = mkServerSecrets cfg.hera;
    };

    networking.wg-quick.interfaces = {
      feb-router = mkIf cfg.feb-router.enable {
        autostart = false;
        address = ["192.168.98.${toString cfg.feb-router.lastOctect}/24"];
        privateKeyFile = config.age.secrets.wireguardClientFebRouterPrivateKey.path;

        peers = [
          {
            publicKey = "tOAfW4lPiVyyRepRtzBq4SIfQkfKFstwFq9jAGUINF4=";
            allowedIPs = ["192.168.98.0/24" "192.168.99.0/24" "192.168.0.0/21" "192.168.20.0/22"];
            endpoint = "wireguard.feb.diogotc.com:51820";
          }
        ];
      };
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
