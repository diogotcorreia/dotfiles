# Configuration for Immich on Hera
{
  config,
  lib,
  ...
}: let
  cfg = config.services.immich;

  photosLocation = "/persist/immich";
  photosLocationNfs = "/mnt/diskstation/immich";

  domain = "photos.diogotc.com";
  port = lib.my.ports.immich;
in {
  # Ensure that the NFS server has the same UID/GID
  users.users.${cfg.user}.uid = 15015;
  users.groups.${cfg.group}.gid = 15015;

  services.immich = {
    inherit port;

    enable = true;
    mediaLocation = photosLocation;

    settings = {
      # disable built-in database backup; we already have our own
      backup.database.enabled = false;

      # domain for public share links
      server.externalDomain = "https://${domain}";

      # import faces from EXIF data
      metadata.faces.import = true;

      # move assets to the `library` directory after uploading
      storageTemplate.enabled = true;

      # disable update checker
      newVersionCheck.enabled = false;
    };
  };

  systemd.tmpfiles.rules = ["d ${photosLocation} 0750 ${cfg.user} ${cfg.group}"];

  fileSystems = let
    mkBindMount = dir:
      lib.nameValuePair
      "${photosLocation}/${dir}"
      {
        depends = [
          "/mnt/diskstation"
          "/persist"
        ];
        device = "${photosLocationNfs}/${dir}";
        fsType = "none";
        options = [
          "bind"
          # since /mnt/diskstation is an automount, this also has to be
          # otherwise it won't remount when that network share is remounted
          "x-systemd.automount"
          "noauto"
        ];
      };
  in
    builtins.listToAttrs [
      (mkBindMount "library")
      (mkBindMount "encoded-video")
    ];

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        reverse_proxy localhost:${toString port}
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
