# hosts/bacchus/cscpt.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Temporary configuration for Cybersecurity Challenge Portugal

{ config, hostSecretsDir, ... }: {

  # CSC-PT Wireguard VPN
  networking.wg-quick.interfaces = {
    cscpt = {
      autostart = false;
      address = [ "10.123.123.15/32" ];
      # public key = TvdKrAyIGyomadf1Z3F88qy6q+AXGWxCMMbuAEQ0USY=
      privateKeyFile = config.age.secrets.bacchusCscptWireguardPrivateKey.path;

      peers = [{
        publicKey = "TAakuUUYICXaDOVamxYhJRRkJKt7pGhzHOgr1exCjGI=";
        allowedIPs = [ "10.123.123.1/32" ];
        endpoint = "game.cybersecuritychallenge.pt:31337";
        persistentKeepalive = 25;
      }];
    };
  };

  age.secrets.bacchusCscptWireguardPrivateKey.file =
    "${hostSecretsDir}/cscptWireguardPrivateKey.age";

}
