# hosts/phobos/uptime-kuma.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Uptime Kuma on Phobos

{ pkgs, config, ... }:
let port = 8002;
in {

  services.uptime-kuma = {
    enable = true;
    settings = { PORT = toString port; };
    package = pkgs.unstable.uptime-kuma;
  };

  services.caddy.virtualHosts."uptime.diogotc.com" = {
    extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };

  # FIXME: hardcoded directory because restic doesn't follow symlinks
  # See https://github.com/restic/restic/pull/3863
  modules.services.restic.paths = [ "/var/lib/private/uptime-kuma" ];

}
