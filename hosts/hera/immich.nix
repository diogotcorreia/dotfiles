# Configuration for Immich on Hera
# Adapted from https://github.com/solomon-b/nixos-config/blob/87bd7ad355d8de2897f13a0f0e96739ff6d06196/config/machines/servers/sower/immich.nix
{
  pkgs,
  config,
  ...
}: let
  images = {
    server = {
      imageName = "ghcr.io/immich-app/immich-server";
      imageDigest = "sha256:27ceb1867f5501818c86188c62924bbfd3024d8f74395cd66d6a302b01d1b2cd"; # v1.122.2
      sha256 = "sha256-pVyvjOxGsh6XGDhlIr9YeBstZbGKOTjgArri4HntTfY=";
    };
    machineLearning = {
      imageName = "ghcr.io/immich-app/immich-machine-learning";
      imageDigest = "sha256:5c4e7a25a01e4dd52e9b919a277a2d870af0a08094e4089c85708e402512a8aa"; # v1.122.2
      sha256 = "sha256-QdSHx6TF0KXE8qS+9+6UkESHr15rTUL8v3XU9pkP3JA=";
    };
  };
  dbUsername = user;

  redisName = "immich";

  photosLocation = "/persist/immich";
  photosLocationNfs = "/mnt/diskstation/immich";

  user = "immich";
  group = user;
  # Ensure that the NFS server has the same UID/GID
  uid = 15015;
  gid = 15015;

  immichServerUrl = "http://immich_server:3001";
  immichMachineLearningUrl = "http://immich_machine_learning:3003";

  domain = "photos.diogotc.com";
  immichExternalPort = 8084;

  environment = {
    DB_URL = "socket://${dbUsername}:@/run/postgresql?db=${dbUsername}";

    REDIS_SOCKET = config.services.redis.servers.${redisName}.unixSocket;

    UPLOAD_LOCATION = photosLocation;

    IMMICH_SERVER_URL = immichServerUrl;
    IMMICH_MACHINE_LEARNING_URL = immichMachineLearningUrl;
  };

  mkMount = dir: "${dir}:${dir}";
in {
  users.users.${user} = {
    inherit group uid;
    isSystemUser = true;
  };
  users.groups.${group} = {inherit gid;};

  services.postgresql = {
    ensureUsers = [
      {
        name = dbUsername;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [dbUsername];

    extensions = ps:
      with ps; [
        pgvecto-rs
      ];
    settings = {shared_preload_libraries = "vectors.so";};
  };

  services.redis.servers.${redisName} = {
    inherit user;
    enable = true;
  };

  systemd.tmpfiles.rules = ["d ${photosLocation} 0750 ${user} ${group}"];

  virtualisation.oci-containers.containers = {
    immich_server = {
      imageFile = pkgs.dockerTools.pullImage images.server;
      image = "ghcr.io/immich-app/immich-server";
      extraOptions = ["--network=immich-bridge" "--user=${toString uid}:${toString gid}"];

      volumes = [
        "${photosLocation}:/usr/src/app/upload"
        "${photosLocationNfs}/library:/usr/src/app/upload/library"
        "${photosLocationNfs}/encoded-video:/usr/src/app/upload/encoded-video"
        (mkMount "/run/postgresql")
        (mkMount "/run/redis-${redisName}")
      ];

      environment =
        environment
        // {
          PUID = toString uid;
          PGID = toString gid;
        };

      ports = ["${toString immichExternalPort}:2283"];

      autoStart = true;
    };

    immich_machine_learning = {
      imageFile = pkgs.dockerTools.pullImage images.machineLearning;
      image = "ghcr.io/immich-app/immich-machine-learning";
      extraOptions = ["--network=immich-bridge"];

      environment = environment;

      volumes = ["immich-model-cache:/cache"];

      autoStart = true;
    };
  };

  systemd.services = let
    backend = config.virtualisation.oci-containers.backend;
  in {
    # Restart Immich container when postgresql restarts,
    # otherwise it loses connection to the socket
    "${backend}-immich_server".requires = ["postgresql.service"];

    init-immich-network = {
      description = "Create the network bridge for immich.";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
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
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString immichExternalPort}
      '';
    };
  };

  # https://immich.app/docs/administration/backup-and-restore
  modules.services.restic.paths = [
    "${photosLocationNfs}/library"
    "${photosLocation}/upload"
    "${photosLocation}/profile"
  ];
}
