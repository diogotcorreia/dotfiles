# Common configuration for caddy reverse proxy
{lib, ...}: {
  # Open firewall ports
  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    extraConfig = ''
      # Rules for services behind Cloudflare proxy
      (CLOUDFLARE_PROXY) {
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
      }

      # Rules for services behind Nebula VPN (192.168.100.1/24)
      (NEBULA) {
        # Nebula + Docker
        @not-nebula not remote_ip 192.168.100.1/24 172.16.0.0/12
        abort @not-nebula
      }

      # Rules for services behind Authelia
      (AUTHELIA) {
        @not_healthchecks {
          not {
            method GET
            path /
            remote_ip 192.168.100.7 # phobos
          }
        }
        forward_auth @not_healthchecks 192.168.100.1:9091 {
          uri /api/verify?rd=https://auth.diogotc.com/
          copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
      }
    '';
  };

  # Restrict caddy admin endpoint to the caddy user
  systemd.services.caddy = {
    environment = {
      CADDY_ADMIN = "unix///run/caddy/caddy.sock";
    };
    serviceConfig = {
      RuntimeDirectory = "caddy";
    };
  };

  # Ensure nginx isn't turned on by some services (e.g. services using PHP)
  services.nginx.enable = lib.mkForce false;
}
