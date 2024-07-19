# Discord bot to provide alternative URLS to various social media sites
{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: {
  age.secrets.altUrlsDiscordBotEnv.file = secrets.host.altUrlsDiscordBotEnv;

  systemd.services.alt-urls-discord-bot = {
    description = "Alt URLS Discord Bot";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      ExecStart = "${lib.getExe pkgs.my.alt-urls-discord-bot}";
      Restart = "on-failure";
      EnvironmentFile = [config.age.secrets.altUrlsDiscordBotEnv.path];

      # systemd hardening
      NoNewPrivileges = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = !config.boot.isContainer;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      ProtectControlGroups = !config.boot.isContainer;
      ProtectHostname = true;
      ProtectKernelLogs = !config.boot.isContainer;
      ProtectKernelModules = !config.boot.isContainer;
      ProtectKernelTunables = !config.boot.isContainer;
      LockPersonality = true;
      PrivateTmp = !config.boot.isContainer;
      PrivateDevices = true;
      PrivateUsers = true;
      RemoveIPC = true;

      SystemCallFilter = [
        "~@clock"
        "~@aio"
        "~@chown"
        "~@cpu-emulation"
        "~@debug"
        "~@keyring"
        "~@memlock"
        "~@module"
        "~@mount"
        "~@obsolete"
        "~@privileged"
        "~@raw-io"
        "~@reboot"
        "~@setuid"
        "~@swap"
      ];
      SystemCallErrorNumber = "EPERM";
    };
  };
}
