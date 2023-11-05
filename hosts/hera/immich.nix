# hosts/hera/immich.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Immich on Hera
# Adapted from https://github.com/solomon-b/nixos-config/blob/87bd7ad355d8de2897f13a0f0e96739ff6d06196/config/machines/servers/sower/immich.nix

{ pkgs, config, ... }:

let
  dbUsername = "immich";
  dbDatabaseName = "immich";

  redisName = "immich";

  photosLocation = "/persist/immich";

  user = "immich";
  group = user;
  uid = 15015;
  gid = 15015;

  immichWebUrl = "http://immich_web:3000";
  immichServerUrl = "http://immich_server:3001";
  immichMachineLearningUrl = "http://immich_machine_learning:3003";

  domain = "photos.diogotc.com";
  immichExternalPort = 8084;

  typesenseApiKey =
    "abcxyz123"; # doesn't matter since it's not accessible from the outside

  environment = {
    DB_URL = "socket://${dbUsername}:@/run/postgresql?db=${dbDatabaseName}";

    REDIS_SOCKET = config.services.redis.servers.${redisName}.unixSocket;

    UPLOAD_LOCATION = photosLocation;

    TYPESENSE_API_KEY = typesenseApiKey;

    IMMICH_WEB_URL = immichWebUrl;
    IMMICH_SERVER_URL = immichServerUrl;
    IMMICH_MACHINE_LEARNING_URL = immichMachineLearningUrl;
  };

  wrapImage = { name, imageName, imageDigest, sha256, entrypoint }:
    pkgs.dockerTools.buildImage ({
      name = name;
      tag = "release";
      fromImage = pkgs.dockerTools.pullImage {
        imageName = imageName;
        imageDigest = imageDigest;
        sha256 = sha256;
      };
      created = "now";
      config = if builtins.length entrypoint == 0 then
        null
      else {
        Cmd = entrypoint;
        WorkingDir = "/usr/src/app";
      };
    });
  mkMount = dir: "${dir}:${dir}";
in {
  users.users.${user} = {
    inherit group uid;
    isSystemUser = true;
  };
  users.groups.${group} = { inherit gid; };

  services.postgresql = {
    ensureUsers = [{
      name = dbUsername;
      ensurePermissions = {
        "DATABASE \"${dbDatabaseName}\"" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ dbDatabaseName ];
  };

  services.redis.servers.${redisName} = {
    inherit user;
    enable = true;
  };

  systemd.tmpfiles.rules = [ "d ${photosLocation} 0750 ${user} ${group}" ];

  virtualisation.oci-containers.containers = {
    immich_server = {
      imageFile = wrapImage {
        name = "immich_server";
        imageName = "ghcr.io/immich-app/immich-server";
        imageDigest =
          "sha256:3440f320004fe32a95d6dd7b6359de6a352218b931103ad70d8f73088aae255d"; # v1.84.0
        sha256 = "sha256-DDsXHZD/I549z+oy3hw4ZE2alCPRiqTkZ+QNpYk+Uhw=";
        entrypoint = [ "/bin/sh" "start-server.sh" ];
      };
      image = "immich_server:release";
      extraOptions =
        [ "--network=immich-bridge" "--user=${toString uid}:${toString gid}" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        (mkMount "/run/postgresql")
        (mkMount "/run/redis-${redisName}")
      ];

      environment = environment // {
        PUID = toString uid;
        PGID = toString gid;
      };

      dependsOn = [ "typesense" ];

      autoStart = true;
    };

    immich_microservices = {
      imageFile = wrapImage {
        name = "immich_microservices";
        imageName = "ghcr.io/immich-app/immich-server";
        imageDigest =
          "sha256:3440f320004fe32a95d6dd7b6359de6a352218b931103ad70d8f73088aae255d"; # v1.84.0
        sha256 = "sha256-DDsXHZD/I549z+oy3hw4ZE2alCPRiqTkZ+QNpYk+Uhw=";
        entrypoint = [ "/bin/sh" "start-microservices.sh" ];
      };
      image = "immich_microservices:release";
      extraOptions =
        [ "--network=immich-bridge" "--user=${toString uid}:${toString gid}" ];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        (mkMount "/run/postgresql")
        (mkMount "/run/redis-${redisName}")
      ];

      environment = environment // {
        PUID = toString uid;
        PGID = toString gid;
        REVERSE_GEOCODING_DUMP_DIRECTORY = "/tmp/reverse-geocoding-dump";
      };

      dependsOn = [ "typesense" ];

      autoStart = true;
    };

    immich_machine_learning = {
      imageFile = pkgs.dockerTools.pullImage {
        imageName = "ghcr.io/immich-app/immich-machine-learning";
        imageDigest =
          "sha256:3ca2825ccfe44eacc8c856e1cf66bdf6f7354b752d8bbebee91f2f64b79c5675"; # v1.84.0
        sha256 = "sha256-0sYIXd50+Ln/QDIlIF1os0/z+Ub5mKZ7b1gJ1KJ144s=";
      };
      image = "ghcr.io/immich-app/immich-machine-learning";
      extraOptions = [ "--network=immich-bridge" ];

      environment = environment;

      volumes = [ "immich-model-cache:/cache" ];

      autoStart = true;
    };

    immich_web = {
      imageFile = pkgs.dockerTools.pullImage {
        imageName = "ghcr.io/immich-app/immich-web";
        imageDigest =
          "sha256:cd199bc511516cf4af3e6b2ae83a4ad1abd852464cfb29cda21759601c5ba15c"; # v1.84.0
        sha256 = "sha256-SFwLvG5x8nT8/XKRGTSseiLDSIezq+63wKsIVKGin/8=";
      };
      image = "ghcr.io/immich-app/immich-web";
      extraOptions = [ "--network=immich-bridge" ];

      environment = environment;

      autoStart = true;
    };

    typesense = {
      image = "typesense/typesense:0.24.0";
      extraOptions = [ "--network=immich-bridge" ];

      environment = {
        TYPESENSE_API_KEY = typesenseApiKey;
        TYPESENSE_DATA_DIR = "/data";
      };

      log-driver = "none";

      volumes = [ "immich-tsdata:/data" ];

      autoStart = true;
    };

    immich_proxy = {
      imageFile = pkgs.dockerTools.pullImage {
        imageName = "ghcr.io/immich-app/immich-proxy";
        imageDigest =
          "sha256:277290787ca1ffca88b51088a581ed0a9c344ccb650ef435469c602d10d67b7e"; # 1.84.0
        sha256 = "sha256-LMASqIUZinjwxd5Hf24c89Iot9cXa2xOd2TELTI0ATg=";
      };
      image = "ghcr.io/immich-app/immich-proxy:release";
      extraOptions = [ "--network=immich-bridge" ];

      environment = {
        IMMICH_SERVER_URL = immichServerUrl;
        IMMICH_WEB_URL = immichWebUrl;
        IMMICH_MACHINE_LEARNING_URL = immichMachineLearningUrl;
      };

      log-driver = "none";

      dependsOn = [ "typesense" ];

      ports = [ "${toString immichExternalPort}:8080" ];

      autoStart = true;
    };
  };

  systemd.services.init-immich-network = {
    description = "Create the network bridge for immich.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Put a true at the end to prevent getting non-zero return code, which will
      # crash the whole service.
      check=$(${pkgs.docker}/bin/docker network ls | grep "immich-bridge" || true)
      if [ -z "$check" ];
        then ${pkgs.docker}/bin/docker network create immich-bridge
        else echo "immich-bridge already exists in docker"
      fi
    '';
  };

  security.acme.certs.${domain} = { };

  services.caddy.virtualHosts = {
    ${domain} = {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString immichExternalPort}
      '';
    };
  };

  # https://immich.app/docs/administration/backup-and-restore
  modules.services.restic.paths = [
    "${photosLocation}/library"
    "${photosLocation}/upload"
    "${photosLocation}/profile"
  ];
}
