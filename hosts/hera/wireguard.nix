# Wireguard server on Hera
{
  pkgs,
  config,
  hostSecretsDir,
  ...
}: let
  listenPort = 51820;

  outInterface = config.networking.nat.externalInterface;

  subnet = "192.168.101";

  mkPeers = builtins.map (peer: {
    inherit (peer) publicKey;
    allowedIPs = ["${subnet}.${toString peer.lastOctect}/32" "fc00:192:168:101::${toString peer.lastOctect}/128" "224.0.0.0/24" "ff00::/16"];
  });
in {
  networking.nat.internalInterfaces = ["wg0"];
  networking.firewall = {
    allowedUDPPorts = [listenPort];
  };

  age.secrets = {
    wireguardPrivateKey.file = "${hostSecretsDir}/wireguardPrivateKey.age";
  };

  networking.wireguard.interfaces = {
    wg0 = {
      inherit listenPort;
      # corresponding public key: XM/VFX/CWunMSiJX0tcv7F/ShDHPlP4RCySvbPkqHHQ=
      privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
      ips = ["${subnet}.1/24"];
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet}.0/24 -o ${outInterface} -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet}.0/24 -o ${outInterface} -j MASQUERADE
      '';

      peers = mkPeers [
        {
          # xiaomi11tpro
          publicKey = "YVATyja/uqW4BJMu9z/FXQZXivSb3USK0+e+/lWuUl8=";
          lastOctect = 2;
        }
        {
          # bacchus
          publicKey = "HitADKIgPbbk2fhCxd9iuTsT683ayLithrwnQagb4B0=";
          lastOctect = 3;
        }
      ];
    };
  };
}
