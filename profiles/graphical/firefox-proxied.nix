# Firefox profile that is connected to a proxy
{
  lib,
  pkgs,
  profiles,
  ...
}: let
  socksBindAddr = "localhost";
  socksPort = 9000;
in {
  imports = with profiles; [
    # Requires firefox profile
    graphical.firefox
  ];

  # Alias to open profile
  hm.home.packages = [
    (
      pkgs.writeScriptBin "firefox-proxied" ''
        ${lib.getExe pkgs.firefox} -P proxied
      ''
    )
  ];

  hm.programs.firefox.profiles.proxied = {
    id = 2;
    settings = {
      "network.proxy.socks" = socksBindAddr;
      "network.proxy.socks_port" = socksPort;
      "network.proxy.type" = 1;
    };
  };
}
