# Wireguard configuration for European Cybersecurity Challenge
{
  config,
  secrets,
  ...
}: {
  age.secrets = {
    wireguardClientEcscJeopardyPrivateKey = {
      file = secrets.ecscJeopardyWireguardPrivateKey;
    };
    wireguardClientEcscAdPrivateKey = {
      file = secrets.ecscAdWireguardPrivateKey;
    };
    wireguardClientHeroisDoMarPrivateKey = {
      file = secrets.heroisDoMarWireguardPrivateKey;
    };
  };

  networking.wg-quick.interfaces = {
    ecsc-jeopardy = {
      autostart = false;
      address = ["10.150.0.12/32"];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientEcscJeopardyPrivateKey.path;

      peers = [
        {
          publicKey = "t402PhZ6mDUn3tbE4dEqFrIkchmcmPC8KUj+dKOqWV0=";
          endpoint = "10.181.1.28:51820";
          allowedIPs = ["10.150.0.0/16" "10.151.0.0/16" "10.250.0.0/16" "10.251.0.0/16"];
          persistentKeepalive = 5;
        }
      ];
    };
    ecsc-ad = {
      autostart = false;
      address = ["10.81.28.12/32"];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientEcscAdPrivateKey.path;

      peers = [
        {
          publicKey = "FggpF3rZKjvqeuqjLr8U2bilZIckJWV8nJYCn7ZocVo=";
          endpoint = "10.181.4.1:51820";
          allowedIPs = ["10.254.0.0/24" "10.60.0.0/14" "10.64.0.0/14" "10.68.0.0/14" "10.80.0.0/16" "10.81.0.0/16" "10.10.0.0/16" "10.11.0.0/16"];
          persistentKeepalive = 5;
        }
      ];
    };
    herois-do-mar = {
      autostart = false;
      address = ["192.168.69.11/32"];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientHeroisDoMarPrivateKey.path;

      peers = [
        {
          publicKey = "QsOHIM2cPQrmuDC3+NTpQ2yXEdMlZgSazYmIFmiKsxQ=";
          endpoint = "vpn.cscpt.dei.pt:51820";
          allowedIPs = ["192.168.69.0/24"];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
