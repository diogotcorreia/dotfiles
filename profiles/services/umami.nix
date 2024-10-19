# Module for deploying umami analytics
# Unfortunately using Docker since there's no nix package (yet)
# https://github.com/NixOS/nixpkgs/issues/172063
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  image = {
    imageName = "ghcr.io/umami-software/umami";
    imageDigest = "sha256:611cacc80f53fe289f7e7bfe301032a117fb57e790c37272ee05f3b0eba690a3"; # postgresql-v2.13.2
    sha256 = "sha256-Zfjha/J0l5c61u3TqeBclns3ZnWs8IssQh7d8TWbBn0=";
  };
  dbUsername = user;

  user = "umami";
  group = user;
  uid = 35394;
  gid = 35394;

  domain = "analytics.diogotc.com";
  umamiExternalPort = 8380;

  environment = {
    DATABASE_URL = "postgresql://${dbUsername}@localhost/${dbUsername}?host=/run/postgresql";
    DATABASE_TYPE = "postgresql";

    # Container doesn't work with a custom user and this.
    # Set this in caddy instead.
    # TRACKER_SCRIPT_NAME = lib.concatStringsSep "," trackerScripts;
    # COLLECT_API_ENDPOINT = collectApiEndpoint;

    DISABLE_TELEMETRY = "1";
  };

  trackerScripts = ["script.js" "umami.js" "hellothere.js"];
  collectApiEndpoint = "/api/abc-send";

  mkMount = dir: "${dir}:${dir}";

  # Hack: update endpoint in tracker script
  trackerScript = pkgs.fetchurl {
    url = "https://github.com/umami-software/umami/raw/refs/tags/v2.13.2/src/tracker/index.js";
    hash = "sha256-N+iraFgl0vwIqn7irjUyZfAbEPUDGh7P/C2fgRZYnMM=";
  };
  trackerScriptsDir =
    pkgs.runCommand "umami-trackers-dir" {
      nativeBuildInputs = [pkgs.minify];
    } ''
      minify -o tracker.js ${trackerScript}
      substituteInPlace tracker.js \
        --replace-fail '__COLLECT_API_HOST__' "" \
        --replace-fail '__COLLECT_API_ENDPOINT__' ${lib.escapeShellArg collectApiEndpoint}

      mkdir $out
      ${lib.concatStringsSep "\n" (map (file: "cp tracker.js $out/${lib.escapeShellArg file}") trackerScripts)}
    '';
in {
  users.users.${user} = {
    inherit group uid;
    isSystemUser = true;
  };
  users.groups.${group} = {inherit gid;};

  age.secrets = {
    umamiEnv.file = secrets.host.umamiEnv;
  };

  services.postgresql = {
    enable = lib.mkDefault true;
    ensureUsers = [
      {
        name = dbUsername;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [dbUsername];
  };

  virtualisation.oci-containers.containers = {
    umami = {
      inherit environment;

      imageFile = pkgs.dockerTools.pullImage image;
      image = image.imageName;

      user = "${toString uid}:1001";

      volumes = [
        (mkMount "/run/postgresql")
      ];

      environmentFiles = [
        # Contains:
        # - HASH_SALT
        config.age.secrets.umamiEnv.path
      ];

      ports = ["${toString umamiExternalPort}:3000"];

      autoStart = true;
    };
  };

  systemd.services = let
    backend = config.virtualisation.oci-containers.backend;
  in {
    # Restart Umami container when postgresql restarts,
    # otherwise it loses connection to the socket
    "${backend}-umami".requires = ["postgresql.service"];
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      serverAliases = ["umami.diogotc.com"];
      extraConfig = ''
        root * ${trackerScriptsDir}

        @exists file
        handle @exists {
          file_server
        }

        handle {
          rewrite ${collectApiEndpoint} /api/send
          reverse_proxy localhost:${toString umamiExternalPort}
        }
      '';
    };
  };
}
