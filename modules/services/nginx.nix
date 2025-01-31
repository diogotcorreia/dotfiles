# Extra options for the nixpkgs nginx module
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;

  realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
  # last updated: 2024-12-31
  # https://www.cloudflare.com/ips/
  cfipv4 = fileToList (pkgs.fetchurl {
    url = "https://www.cloudflare.com/ips-v4";
    hash = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
  });
  cfipv6 = fileToList (pkgs.fetchurl {
    url = "https://www.cloudflare.com/ips-v6";
    hash = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
  });
in {
  options.services.nginx = {
    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule (
        {config, ...}: {
          options = {
            enableCloudflareRealIp = mkEnableOption "getting IP address from CF-Connecting-IP header";
          };
          config = {
            # sane default: redirect to HTTPS automatically
            forceSSL = mkDefault config.enableACME;
            # sane default: use DNS-01 challenge instead of HTTP-01
            acmeRoot = mkDefault null;

            extraConfig = mkIf config.enableCloudflareRealIp ''
              ${realIpsFromList cfipv4}
              ${realIpsFromList cfipv6}
              real_ip_header CF-Connecting-IP;
            '';
          };
        }
      ));
    };
  };
}
