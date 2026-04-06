{
  config,
  lib,
  ...
}:
{
  hm.programs.fish = lib.mkIf config.virtualisation.containers.enable {
    shellAbbrs = {
      # https://github.com/ohmyzsh/ohmyzsh/blob/887a864aba396c0e6dcf7c0254f455676f830daa/plugins/docker-compose/docker-compose.plugin.zsh
      dco = "docker compose";
      dcb = "docker compose build";
      dce = "docker compose exec";
      dcps = "docker compose ps";
      dcrestart = "docker compose restart";
      dcrm = "docker compose rm";
      dcr = "docker compose run";
      dcstop = "docker compose stop";
      dcup = "docker compose up";
      dcupb = "docker compose up --build";
      dcupd = "docker compose up -d";
      dcupdb = "docker compose up -d --build";
      dcdn = "docker compose down";
      dcl = "docker compose logs";
      dclf = "docker compose logs -f";
      dclF = "docker compose logs -f --tail 0";
      dcpull = "docker compose pull";
      dcstart = "docker compose start";
      dck = "docker compose kill";

      # https://github.com/ohmyzsh/ohmyzsh/blob/887a864aba396c0e6dcf7c0254f455676f830daa/plugins/docker/docker.plugin.zsh
      dbl = "docker build";
      dcin = "docker container inspect";
      dcls = "docker container ls";
      dclsa = "docker container ls -a";
      dcprune = "docker container prune";
      dib = "docker image build";
      dii = "docker image inspect";
      dils = "docker image ls";
      dipu = "docker image push";
      dipru = "docker image prune -a";
      dirm = "docker image rm";
      dit = "docker image tag";
      dlo = "docker container logs";
      dnc = "docker network create";
      dncn = "docker network connect";
      dndcn = "docker network disconnect";
      dni = "docker network inspect";
      dnls = "docker network ls";
      dnprune = "docker network prune";
      dnrm = "docker network rm";
      dpo = "docker container port";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dpu = "docker pull";
      dr = "docker container run";
      drit = "docker container run -it";
      drm = "docker container rm";
      "drm!" = "docker container rm -f";
      dsprune = "docker system prune";
      dst = "docker container start";
      drs = "docker container restart";
      dsta = "docker stop $(docker ps -q)";
      dstp = "docker container stop";
      dsts = "docker stats";
      dtop = "docker top";
      dvi = "docker volume inspect";
      dvls = "docker volume ls";
      dvprune = "docker volume prune";
      dxc = "docker container exec";
      dxcit = "docker container exec -it";
    };
  };
}
