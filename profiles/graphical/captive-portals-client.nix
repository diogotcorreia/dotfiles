# Browser to login into WiFi captive portals
{
  config,
  lib,
  pkgs,
  profiles,
  ...
}: let
  socksBindAddr = "localhost";
  socksPort = 1666;
in {
  imports = with profiles; [
    # Requires firefox profile
    graphical.firefox
  ];

  programs.captive-browser = {
    enable = true;
    socks5-addr = "${socksBindAddr}:${toString socksPort}";
    interface = config.my.networking.wirelessInterface;

    # Adapt captive-browser to use Firefox:
    # https://github.com/FiloSottile/captive-browser/issues/20
    browser = "${lib.getExe pkgs.firefox} -P captive-browser --private-window http://detectportal.firefox.com/canonical.html";
  };

  hm.programs.firefox.profiles.captive-browser = {
    id = 1;
    settings = {
      "network.proxy.socks" = socksBindAddr;
      "network.proxy.socks_port" = socksPort;
      "network.proxy.socks_remote_dns" = true;
      "network.proxy.type" = 1;

      # disable https-only in case it interferes
      "dom.security.https_only_mode" = false;
    };
  };
}
