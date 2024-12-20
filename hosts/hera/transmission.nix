# Configuration for Transmission on Hera
{
  config,
  secrets,
  lib,
  pkgs,
  ...
}: let
  domain = "transmission.hera.diogotc.com";
  port = 9091;

  socksSocket = "/run/${socketDirectory}/transmission-socks-proxy";
  socketDirectory = "transmission-proxy";
in {
  age.secrets = {
    # Contains:
    # Host proxy
    #   HostName <host>
    #   User <username>
    #   KnownHostsCommand /usr/bin/env printf "%H ssh-ed25519 <host public key>"
    transmissionProxySshConfig.file = secrets.host.transmissionProxySshConfig;
    # Contains password for remote SSH user
    transmissionProxySshPassword.file = secrets.host.transmissionProxySshPassword;
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    webHome = pkgs.unstable.flood-for-transmission;

    settings = {
      rpc-host-whitelist = domain;
    };
  };

  # Setup SOCKS proxy for transmission
  systemd.services.transmission.environment.all_proxy = "socks5h://localhost:9123";

  # https://unix.stackexchange.com/questions/383678/on-demand-ssh-socks-proxy-through-systemd-user-units-with-socket-activation-does
  systemd.services.transmission-socks-proxy = {
    description = "SOCKS5 proxy for transmission";
    unitConfig = {
      StopWhenUnneeded = true;
    };
    serviceConfig = let
      sshOptions = {
        ExitOnForwardFailure = "yes";
        ControlMaster = "no";
        StreamLocalBindUnlink = "yes";
        PermitLocalCommand = "yes";
        LocalCommand = "${lib.getExe' pkgs.systemd "systemd-notify"} --ready";
        UserKnownHostsFile = "/dev/null"; # don't add to known hosts, have the config provide the public key in the secret file
      };
      finalSshOptions = lib.pipe sshOptions [
        (lib.mapAttrsToList (key: value: ["-o" "${key}=${value}"]))
        lib.flatten
        lib.escapeShellArgs
      ];

      configFile = config.age.secrets.transmissionProxySshConfig.path;
      passwordFile = config.age.secrets.transmissionProxySshPassword.path;

      sshCommand = "${lib.getExe pkgs.openssh} -D ${socksSocket} -kaxNT ${finalSshOptions} -F ${configFile} proxy";
    in {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "-${lib.getExe pkgs.passh} -p file:${passwordFile} ${sshCommand}";

      RuntimeDirectory = socketDirectory;
      RuntimeDirectoryMode = "0750";
    };
  };
  systemd.services.transmission-socks-proxy-facade = {
    description = "Socket-activation for transmission's SOCKS5 proxy";

    bindsTo = [
      "transmission-socks-proxy-facade.socket"
      "transmission-socks-proxy.service"
    ];
    after = [
      "transmission-socks-proxy-facade.socket"
      "transmission-socks-proxy.service"
    ];

    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=500s ${socksSocket}";

      RuntimeDirectory = socketDirectory;
      RuntimeDirectoryMode = "0750";
    };
  };
  systemd.sockets.transmission-socks-proxy-facade = {
    description = "Socket-activation for transmission's SOCKS5 proxy";
    listenStreams = [
      "127.0.0.1:9123"
      "[::1]:9123"
    ];
    wantedBy = ["sockets.target"];
  };

  services.caddy.virtualHosts = {
    ${domain} = {
      enableACME = true;
      extraConfig = ''
        import NEBULA
        import AUTHELIA
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  modules.impermanence.directories = [
    config.services.transmission.home
  ];

  modules.services.restic.paths = [
    # backup settings, stats and active torrents
    "${config.services.transmission.home}/.config"
  ];
}
