# Configuration for IHateToBudget on Hera
{config, ...}: let
  domain = "budget-joao.diogotc.com";
  port = 8013;
in {
  # TODO get rid of this, it is unmaintained as of 2022-12-24

  services.caddy.virtualHosts.${domain} = {
    enableACME = true;
    extraConfig = ''
      route /static/* {
        uri strip_prefix /static
        # THIS IS A HACK
        # I hate this, but caddy needs permission since it's not running as root
        # Files have to be copied over manually
        root * /persist/ihatetobudget-static
        file_server {
          browse
        }
      }
      reverse_proxy localhost:${toString port} {
        import CLOUDFLARE_PROXY
      }
    '';
  };

  modules.services.restic.paths = ["${config.my.homeDirectory}/ihatetobudget-joao"];
}
