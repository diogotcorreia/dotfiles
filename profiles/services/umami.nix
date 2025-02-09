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
    imageDigest = "sha256:b96ff776b0e1dfafb3c366a92119b1a72a656c9c20006d47e07df9dbbffe9331"; # postgresql-v2.15.1
    sha256 = "sha256-gR7CrKz0ahW2/HA/mkK+dn11dVxQ05kCwGfBfPgS6Nc=";
  };
  dbUsername = user;

  user = "umami";
  group = user;
  uid = 35394;
  gid = 35394;

  domain = "analytics.diogotc.com";
  umamiExternalPort = lib.my.ports.umami;

  environment = {
    DATABASE_URL = "postgresql://${dbUsername}@localhost/${dbUsername}?host=/run/postgresql";
    DATABASE_TYPE = "postgresql";

    # Container doesn't work with a custom user and this.
    # Set this in nginx instead.
    # TRACKER_SCRIPT_NAME = lib.concatStringsSep "," trackerScripts;
    # COLLECT_API_ENDPOINT = collectApiEndpoint;

    DISABLE_TELEMETRY = "1";
  };

  trackerScripts = ["script.js" "umami.js" "hellothere.js"];
  collectApiEndpoint = "/api/abc-send";

  mkMount = dir: "${dir}:${dir}";

  # Hack: update endpoint in tracker script
  trackerScript = pkgs.fetchurl {
    url = "https://github.com/umami-software/umami/raw/refs/tags/v2.15.1/src/tracker/index.js";
    hash = "sha256-XNopnbKt2MhFSYcMdduml9C9tz3EoohLQ6ok43ZrCv4=";
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

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      serverAliases = ["umami.diogotc.com"];

      root = trackerScriptsDir;

      locations = {
        "/" = {
          tryFiles = "$uri @proxy";
        };

        "@proxy" = {
          proxyPass = "http://localhost:${toString umamiExternalPort}";
          extraConfig = ''
            rewrite ^${collectApiEndpoint}$ /api/send last;
          '';
        };
      };
    };
  };
}
