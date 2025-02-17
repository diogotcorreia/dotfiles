{config, ...}: let
  domain = "esphome.${config.networking.hostName}.diogotc.com";
in {
  services.esphome = {
    enable = true;
    enableUnixSocket = true;
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy unix//run/esphome/esphome.sock
      '';
    };
  };
  # allow access to socket
  systemd.services.caddy.serviceConfig.SupplementaryGroups = ["esphome"];

  my.services.authelia.accessRules = [
    {
      inherit domain;
      subject = "group:esphome-${config.networking.hostName}";
    }
  ];
}
