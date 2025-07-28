{
  config,
  lib,
  pkgs,
  secrets,
  user,
  ...
}:
let
  domain = "rproxy.diogotc.com";
  server = {
    host = "bro.diogotc.com";
    port = lib.my.ports.frpServer;
  };
in
{
  age.secrets.frpAuthEnv = {
    file = secrets.frpAuthEnv;
    owner = user;
  };

  hm.home.packages = [
    pkgs.frp
    (pkgs.writeShellScriptBin "frpc-http" ''
      set -e

      if [ $# -lt 1 ]; then
        echo "Usage: $0 <local-port> [arguments-for-frpc...]" >&2
        exit 1
      fi

      local_port="$1"
      shift

      subdomain="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"

      echo "Proxying port $local_port to:"
      echo "- http://$subdomain.${domain}"
      echo "- https://$subdomain.${domain}"

      set -a # automatically export all variables
      source "${config.age.secrets.frpAuthEnv.path}"
      set +a

      # Run the command
      ${lib.getExe' pkgs.frp "frpc"} http \
        --server-addr "${server.host}" \
        --server-port "${toString server.port}" \
        --token "$FRP_TOKEN" \
        --user "${config.networking.hostName}" \
        --sd "$subdomain" \
        --local-port "$local_port" \
        --proxy-name "$subdomain" \
        "$@"
    '')
  ];
}
