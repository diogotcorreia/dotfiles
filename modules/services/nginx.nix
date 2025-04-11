# Extra options for the nixpkgs nginx module
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    any
    attrValues
    concatLines
    escapeRegex
    mapAttrsToList
    mkBefore
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionalString
    types
    ;

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

  # https://www.authelia.com/integration/proxies/nginx/
  autheliaLocationBlockConfig = pkgs.writeText "authelia-location.conf" ''
    location /internal/authelia/authz {
      internal;
      proxy_pass "http://192.168.100.10:9091/api/authz/auth-request";

      proxy_set_header X-Original-Method $request_method;
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header Content-Length "";
      proxy_set_header Connection "";

      proxy_pass_request_body off;
      proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
      proxy_redirect http:// $scheme://;
      proxy_http_version 1.1;
      proxy_cache_bypass $cookie_session;
      proxy_no_cache $cookie_session;
      proxy_buffers 4 32k;
      client_body_buffer_size 128k;

      send_timeout 5m;
      proxy_read_timeout 240;
      proxy_send_timeout 240;
      proxy_connect_timeout 240;
    }
  '';

  autheliaAuthRequestConfig = pkgs.writeText "authelia-authrequest.conf" ''
    auth_request /internal/authelia/authz;

    auth_request_set $user $upstream_http_remote_user;
    auth_request_set $groups $upstream_http_remote_groups;
    auth_request_set $name $upstream_http_remote_name;
    auth_request_set $email $upstream_http_remote_email;

    proxy_set_header Remote-User $user;
    proxy_set_header Remote-Groups $groups;
    proxy_set_header Remote-Email $email;
    proxy_set_header Remote-Name $name;

    auth_request_set $redirection_url $upstream_http_location;
    error_page 401 =302 $redirection_url;
  '';
in {
  options.services.nginx = {
    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule (
        {config, ...}: {
          options = {
            enableCloudflareRealIp = mkEnableOption "getting IP address from CF-Connecting-IP header";

            autheliaHealthchecksPath = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/api/health";
              description = ''
                The path to allow access from the healthchecks server, skipping authentication.
              '';
            };
            autheliaRules = mkOption {
              type =
                types.coercedTo
                types.str
                (subject: domain: [{inherit domain subject;}])
                (types.functionTo (types.listOf (types.attrsOf types.anything)));
              default = _: [];
              description = ''
                Function that takes a list of domains and returns a list of authelia access rules.
              '';
            };

            restrictToNebula = mkEnableOption "only allow connections from the nebula subnet";

            locations = mkOption {
              type = types.attrsOf (types.submodule (
                {config, ...}: {
                  options = {
                    enableAuthelia = mkEnableOption "authenticating against authelia";
                  };
                  config = {
                    # sane default: enable websockets support if reverse proxy
                    proxyWebsockets = mkDefault (config.proxyPass != null);

                    extraConfig = mkIf config.enableAuthelia ''
                      include ${autheliaAuthRequestConfig};
                    '';
                  };
                }
              ));
            };
          };
          config = let
            hasAuthelia = any (l: l.enableAuthelia) (attrValues config.locations);
          in {
            # sane default: redirect to HTTPS automatically
            forceSSL = mkDefault config.enableACME;
            # sane default: use DNS-01 challenge instead of HTTP-01
            acmeRoot = mkDefault null;

            extraConfig = concatLines [
              (optionalString config.enableCloudflareRealIp ''
                include ${cloudflareRealIpConf};
              '')
              (optionalString config.restrictToNebula ''
                allow 192.168.100.0/24;
                deny all;
              '')
              (optionalString hasAuthelia ''
                include ${autheliaLocationBlockConfig};
              '')
            ];
          };
        }
      ));
    };
  };

  config = mkIf config.services.nginx.enable {
    my.services.authelia.accessRules = let
      rulesForVhost = vhostName: vhostConfig: let
        serverName =
          if vhostConfig.serverName != null
          then vhostConfig.serverName
          else vhostName;
        domains = [serverName] ++ vhostConfig.serverAliases;

        healthchecksBypass = optional (vhostConfig.autheliaHealthchecksPath != null) {
          domain = domains;
          policy = "bypass";
          methods = ["GET"];
          networks = ["192.168.100.7"]; # phobos
          resources = ["^${escapeRegex vhostConfig.autheliaHealthchecksPath}$"];
        };
        rules = vhostConfig.autheliaRules domains;
      in
        mkMerge [(mkBefore healthchecksBypass) rules];
    in
      mkMerge (mapAttrsToList rulesForVhost config.services.nginx.virtualHosts);
  };
}
