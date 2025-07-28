# Fast Reverse Proxy (https://github.com/fatedier/frp)
# Server configuration for wildcard domain
{
  config,
  lib,
  secrets,
  ...
}:
let
  domain = "rproxy.diogotc.com";
  serverPort = lib.my.ports.frpServer;
  vhostPort = lib.my.ports.frpHttp;
in
{
  age.secrets.frpAuthEnv.file = secrets.frpAuthEnv;

  systemd.services.frp.serviceConfig.EnvironmentFile = [
    config.age.secrets.frpAuthEnv.path
  ];
  services.frp = {
    enable = true;
    role = "server";
    settings = {
      bindAddr = "::";
      bindPort = serverPort;
      vhostHTTPPort = vhostPort;

      auth.method = "token";
      auth.token = "{{ .Envs.FRP_TOKEN }}";

      allowPorts = [
        {
          start = 10000;
          end = 11000;
        }
      ];
      subDomainHost = domain;
    };
  };

  modules.services.nebula.firewall.inbound = [
    {
      port = serverPort;
      proto = "tcp";
      group = "dtc";
    }
  ];

  services.nginx.virtualHosts.${domain} = {
    serverAliases = [ "*.${domain}" ];
    enableACME = true;
    forceSSL = false;
    addSSL = true;
    locations."/".proxyPass = "http://[::1]:${toString vhostPort}";
  };
}
