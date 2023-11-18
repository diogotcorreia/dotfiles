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
        "sha256:f260c047e105a8851ee35057a234f5d98ea7e188fa2e666e6cc280d100a8a772"; # v1.87.0
      sha256 = "sha256-M4u9LM3bhCQwpNXWg5sDtnRBA1qtHpvDZUihIhyDMnk=";
    };
    machineLearning = {
      imageName = "ghcr.io/immich-app/immich-machine-learning";
      imageDigest =
        "sha256:9413adc9a2b9a761031b77ce1bfb479aaef3dc46ec57990c5b5646a9e7f853d5"; # v1.87.0
      sha256 = "sha256-heYh0sntPD+1cKoX331OxfzKW6/K3/oVCs01WX8wwMM=";
    };
    web = {
      imageName = "ghcr.io/immich-app/immich-web";
      imageDigest =
        "sha256:2bef28adbcc60a2ee5dee8cafe109e3d5c6b7bca88d90acdd3eec376200a6d6e"; # v1.87.0
      sha256 = "sha256-t7wLNL3nG0znB4Pv/jk1PbQIGQdz7szLLnhxKo+cC3A=";
    };
    proxy = {
      imageName = "ghcr.io/immich-app/immich-proxy";
      imageDigest =
        "sha256:9b60f2a6c9492306d4a2d182ac9274de6d9df6e6680ca7d55c8fd8348adcdaa6"; # 1.87.0
      sha256 = "sha256-EP7Q3A6WAZExf+dGL8ANKQ2OepKCh/Zl7k+0nZxA7L4=";
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

      dependsOn = [ "typesense" ];

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

      dependsOn = [ "typesense" ];

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

    immich_web = {
      imageFile = pkgs.dockerTools.pullImage images.web;
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
      imageFile = pkgs.dockerTools.pullImage images.proxy;
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
