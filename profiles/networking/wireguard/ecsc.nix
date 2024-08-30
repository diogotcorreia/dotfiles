# Wireguard configuration for European Cybersecurity Challenge
{
  config,
  secrets,
  ...
}: {
  age.secrets = {
    wireguardClientEcscPrivateKey = {
      file = secrets.ecscWireguardPrivateKey;
    };
  };

  networking.wg-quick.interfaces = {
    ecsc = {
      autostart = false;
      address = ["10.81.31.10/32"];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientEcscPrivateKey.path;

      peers = [
        {
          publicKey = "hNeM82sCEjqyBK45kRwaSKC9p2+P2YLaaQ+8knvqL3E=";
          endpoint = "vpn.ad.ecsc2024.it:51820";
          allowedIPs = ["10.254.0.0/24" "10.60.0.0/14" "10.64.0.0/14" "10.68.0.0/14" "10.80.0.0/16" "10.81.0.0/16" "10.10.0.0/16" "10.11.0.0/16"];
          persistentKeepalive = 5;
        }
      ];
    };
  };
}
