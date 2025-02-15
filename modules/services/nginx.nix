# Extra options for the nixpkgs nginx module
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkIf mkOption types;

  # last updated: 2024-12-31
  # https://www.cloudflare.com/ips/
  cfipv4 = pkgs.fetchurl {
    url = "https://www.cloudflare.com/ips-v4";
    hash = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
  };
  cfipv6 = pkgs.fetchurl {
    url = "https://www.cloudflare.com/ips-v6";
    hash = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
  };
  cloudflareRealIpConf = pkgs.runCommand "cloudflare-real-ip.conf" {} ''
    echo | cat ${cfipv4} - ${cfipv6} > $out
    sed -i -E 's/^(.+)$/set_real_ip_from \1;/' $out
    echo >> $out
    echo "real_ip_header CF-Connecting-IP;" >> $out
  '';
in {
  options.services.nginx = {
    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule (
        {config, ...}: {
          options = {
            enableCloudflareRealIp = mkEnableOption "getting IP address from CF-Connecting-IP header";

            locations = mkOption {
              type = types.attrsOf (types.submodule (
                {config, ...}: {
                  config = {
                    # sane default: enable websockets support if reverse proxy
                    proxyWebsockets = mkDefault (config.proxyPass != null);
                  };
                }
              ));
            };
          };
          config = {
            # sane default: redirect to HTTPS automatically
            forceSSL = mkDefault config.enableACME;
            # sane default: use DNS-01 challenge instead of HTTP-01
            acmeRoot = mkDefault null;

            extraConfig = mkIf config.enableCloudflareRealIp ''
              include ${cloudflareRealIpConf};
            '';
          };
        }
      ));
    };
  };
}
