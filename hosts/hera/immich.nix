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
          "sha256:76e78d66ff56ad1e377edfcbec079ae506e8b25b89d075d3a2de2ff2f93b882a"; # v1.83.0
        sha256 = "sha256-ZsEEps5MQw/4QQnq9fthEKm+KSUQIN1hA3q4ONh+GCQ=";
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
          "sha256:76e78d66ff56ad1e377edfcbec079ae506e8b25b89d075d3a2de2ff2f93b882a"; # v1.83.0
        sha256 = "sha256-ZsEEps5MQw/4QQnq9fthEKm+KSUQIN1hA3q4ONh+GCQ=";
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
          "sha256:e2e921f8f0e496dcf051a42dd934bcd57724fb91784a2ec70a3d9d4aea1675f8"; # v1.83.0
        sha256 = "sha256-Y1hA3QVZKa8onMUehF0VoUqRThY42PhMHoWSe/eWdq0=";
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
          "sha256:7ac4af26ec224864316cae1cfe0a0d0a2dd2e2cd12f2e8217cc833c490e110f4"; # v1.83.0
        sha256 = "sha256-SHWmgE3bJGyNDTWwpLuINn+OWz0yMYdVDV1qzJmojBQ=";
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
          "sha256:fcb6697e7885f4c004b2e308b496d12999c0c6845d150353c312b0c9c7df5de7"; # 1.83.0
        sha256 = "sha256-+eBgzkgZQF0joIFcHFKatVEeV8fyk46BFn9EbA7sEhA=";
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