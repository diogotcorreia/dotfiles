# Configuration for wireguard server
{
  config,
  lib,
  secrets,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  cfg = config.modules.services.wireguard-server;

  listenPort = lib.my.ports.wireguard;
  ipv6Subnet = "fc00:${lib.replaceString "." ":" cfg.subnet}";

  mkPeers = builtins.map (peer: {
    inherit (peer) publicKey;
    allowedIPs = [
      "${cfg.subnet}.${toString peer.lastOctect}/32"
      "${ipv6Subnet}::${toString peer.lastOctect}/128"
    ];
  });
in
{
  options.modules.services.wireguard-server = {
    enable = mkEnableOption "a wireguard server on this host";
    privateKeySecret = mkOption {
      # Required
      type = types.path;
      default = secrets.host.wireguardServerPrivateKey;
      description = "Wireguard Private key. Generate with `nix run pkgs#wireguard-tools genkey > private.key`";
    };
    subnet = mkOption {
      type = types.str;
      example = "192.168.100";
      description = "The /24 subnet to use for this wireguard server";
    };
    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "The interface of the wireguard tunnel";
    };

    peers = mkOption {
      type = types.listOf (
        types.submodule (
          { ... }:
          {
            options = {
              publicKey = mkOption {
                type = types.str;
                description = ''
                  Required. The public key of the peer.
                '';
              };
              lastOctect = mkOption {
                type = types.int;
                description = ''
                  Required. The last octect of the IP address to assign to this peer.
                '';
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        Peers to accept on this VPN tunnel.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.nat = {
      enable = lib.mkDefault true;
      internalInterfaces = [ cfg.interface ];
    };
    networking.firewall = {
      allowedUDPPorts = [ listenPort ];
      filterForward = lib.mkDefault true;
    };

    age.secrets = {
      wireguardServerPrivateKey.file = cfg.privateKeySecret;
    };

    networking.wireguard.interfaces = {
      wg0 = {
        inherit listenPort;
        privateKeyFile = config.age.secrets.wireguardServerPrivateKey.path;
        ips = [
          "${cfg.subnet}.1/24"
          "${ipv6Subnet}::1/64"
        ];

        peers = mkPeers cfg.peers;
      };
    };
  };
}
