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
      imageDigest = "sha256:548ad7547d3c79c35acb933c1b3e42b6d87d190f9c31442c0bfe12585153af33"; # v1.116.0
      sha256 = "sha256-A4XJAky03bJOahstqabFilwxu+snvpoCZJ1HWeHCk5s=";
    };
    machineLearning = {
      imageName = "ghcr.io/immich-app/immich-machine-learning";
      imageDigest = "sha256:823cce72af5b56d08fe33171087dd8512be3f52107a3f0b307212f32329aef55"; # v1.116.0
      sha256 = "sha256-oEivqcqhSdUjyqkdJHkzj1b6sTmxFLmG3LTgdiKDGQc=";
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

    extraPlugins = [
      (pkgs.postgresqlPackages.pgvecto-rs.override {
        postgresql = config.services.postgresql.package;
      })
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

      ports = ["${toString immichExternalPort}:3001"];

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
