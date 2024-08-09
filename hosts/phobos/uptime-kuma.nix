# Configuration for Uptime Kuma on Phobos
{pkgs, ...}: let
  domain = "uptime.diogotc.com";
  port = 8002;
in {
  services.uptime-kuma = {
    enable = true;
    settings = {PORT = toString port;};
    package = pkgs.unstable.uptime-kuma;
  };

  security.acme.certs.${domain} = {};

  services.caddy.virtualHosts.${domain} = {
    useACMEHost = domain;
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

  # FIXME: hardcoded directory because restic doesn't follow symlinks
  # See https://github.com/restic/restic/pull/3863
  modules.services.restic.paths = ["/var/lib/private/uptime-kuma"];
}
