# Wireguard configuration for CTFs
{
  config,
  secrets,
  ...
}:
{
  age.secrets = {
    # pub key: NA8Z1i24Whrp8L+wScHjG1C63H8jhGle67wLX8hdI10=
    wireguardClientHeroisDoMarPrivateKey = {
      file = secrets.heroisDoMarWireguardPrivateKey;
    };
  };

  networking.wg-quick.interfaces = {
    saarctf = {
      autostart = false;
      address = [ "10.69.0.88/32" ];
      mtu = 1300;
      privateKeyFile = config.age.secrets.wireguardClientHeroisDoMarPrivateKey.path;

      peers = [
        {
          publicKey = "oLcvAzvoij2jIgxGEPhOkGyeRSNzBJsFR4ljyB76gDM=";
          endpoint = "vpn.stt.rnl.pt:51820";
          allowedIPs = [
            "10.69.0.0/24"
            "10.32.0.0/15"
          ];
          persistentKeepalive = 25;
        }
      ];
    };
    teameurope = {
      autostart = false;
      address = [ "10.128.24.10/32" ];
      mtu = 1320;
      privateKeyFile = config.age.secrets.wireguardClientHeroisDoMarPrivateKey.path;

      peers = [
        {
          publicKey = "3wf/CxDlNXO/x6yE3Tud31QS+fbQNG6s3UwW+TjL9WA=";
          endpoint = "teameurope.pedroadao.me:42434";
          allowedIPs = [ "10.128.16.1/20" ];
          persistentKeepalive = 25;
        }
      ];
    };
    cscpt = {
      autostart = false;
      address = [ "10.120.16.27/32" ];
      mtu = 1320;
      privateKeyFile = config.age.secrets.wireguardClientHeroisDoMarPrivateKey.path;

      peers = [
        {
          publicKey = "rgD6c4oOZcOed8UOhjXXcHkuzPvOXp88HHep++XUUX0=";
          endpoint = "ctf.cybersecuritychallenge.pt:42410";
          allowedIPs = [ "10.120.16.1/32" ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
