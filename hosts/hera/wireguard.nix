# Wireguard server on Hera
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  listenPort = lib.my.ports.wireguard;

  outInterface = config.networking.nat.externalInterface;

  subnet = "192.168.101";

  mkPeers = builtins.map (peer: {
    inherit (peer) publicKey;
    allowedIPs = [
      "${subnet}.${toString peer.lastOctect}/32"
      "fc00:192:168:101::${toString peer.lastOctect}/128"
      "224.0.0.0/24"
      "ff00::/16"
    ];
  });
in
{
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ listenPort ];
  };

  age.secrets = {
    wireguardPrivateKey.file = secrets.host.wireguardPrivateKey;
  };

  networking.wireguard.interfaces = {
    wg0 = {
      inherit listenPort;
      # corresponding public key: XM/VFX/CWunMSiJX0tcv7F/ShDHPlP4RCySvbPkqHHQ=
      privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
      ips = [ "${subnet}.1/24" ];
      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet}.0/24 -o ${outInterface} -j MASQUERADE
      '';

      # This undoes the above command
      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet}.0/24 -o ${outInterface} -j MASQUERADE
      '';

      peers = mkPeers [
        {
          # bluejay
          publicKey = "ShErgwnyZkfBodbKJYxfVC9JEsJC5U9dkhAIwrQeOXM=";
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
