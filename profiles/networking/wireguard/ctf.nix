# Wireguard configuration for CTFs
{
  config,
  secrets,
  ...
}: {
  age.secrets = {
    wireguardClientHeroisDoMarPrivateKey = {
      file = secrets.heroisDoMarWireguardPrivateKey;
    };
  };

  networking.wg-quick.interfaces = {
    saarctf = {
      autostart = false;
      address = ["10.69.0.88/32"];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientHeroisDoMarPrivateKey.path;

      peers = [
        {
          publicKey = "oLcvAzvoij2jIgxGEPhOkGyeRSNzBJsFR4ljyB76gDM=";
          endpoint = "vpn.stt.rnl.pt:51820";
          allowedIPs = ["10.69.0.0/24" "10.32.0.0/15"];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
