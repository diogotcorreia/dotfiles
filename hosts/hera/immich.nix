# hosts/hera/immich.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for Immich on Hera
# Adapted from https://github.com/solomon-b/nixos-config/blob/87bd7ad355d8de2897f13a0f0e96739ff6d06196/config/machines/servers/sower/immich.nix

{ pkgs, config, ... }:

let
  images = {
    serverAndMicroservices = {
      imageName = "ghcr.io/immich-app/immich-server";
      imageDigest =
        "sha256:dbda82bd14cd90242a12be3e75d8d664baa510fcc3c8c00c9355d7275b2e819a"; # v1.88.1
      sha256 = "sha256-3ysfCQfbpjs/7WFMWz8smeq8dkSXTnvl4D9jRXrqvZI=";
    };
    machineLearning = {
      imageName = "ghcr.io/immich-app/immich-machine-learning";
      imageDigest =
        "sha256:8204aa8196c7c8ca587bb7730fd6cd169d802971b31059fdc457149dfb04ff1b"; # v1.88.1
      sha256 = "sha256-ILLKhqmyCULMG/vnX2/Ht2C/H3r1LTU4mfK+0Y9r5ok=";
    };
  };
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

  typesenseHost = "immich_typesense";
  typesenseApiKey =
    "abcxyz123"; # doesn't matter since it's not accessible from the outside

  environment = {
    DB_URL = "socket://${dbUsername}:@/run/postgresql?db=${dbDatabaseName}";

    REDIS_SOCKET = config.services.redis.servers.${redisName}.unixSocket;

    UPLOAD_LOCATION = photosLocation;

    TYPESENSE_HOST = typesenseHost;
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
        inherit (images.serverAndMicroservices) imageName imageDigest sha256;
        name = "immich_server";
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

      dependsOn = [ typesenseHost ];

      ports = [ "${toString immichExternalPort}:3001" ];

      autoStart = true;
    };

    immich_microservices = {
      imageFile = wrapImage {
        inherit (images.serverAndMicroservices) imageName imageDigest sha256;
        name = "immich_microservices";
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

      dependsOn = [ typesenseHost ];

      autoStart = true;
    };

    immich_machine_learning = {
      imageFile = pkgs.dockerTools.pullImage images.machineLearning;
      image = "ghcr.io/immich-app/immich-machine-learning";
      extraOptions = [ "--network=immich-bridge" ];

      environment = environment;

      volumes = [ "immich-model-cache:/cache" ];

      autoStart = true;
    };

    ${typesenseHost} = {
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
