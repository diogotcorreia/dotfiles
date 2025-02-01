# Legacy redirect to resumos.leic.pt
{pkgs, ...}: let
  unregisterServiceWorker = pkgs.writeTextDir "service-worker.js" ''
    self.addEventListener('install', () => self.skipWaiting());

    self.addEventListener('activate', () => {
      self.registration.unregister();
      self.clients.matchAll({ type: 'window' }).then(clients => {
        for (const client of clients) {
          client.navigate(client.url);
        }
      });
    });
  '';
in {
  services.nginx.virtualHosts = {
    "ist.diogotc.com" = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations = {
        "= /service-worker.js" = {
          root = unregisterServiceWorker;
          extraConfig = ''
            add_header Cache-Control no-cache;
            add_header Cache-Control no-store;
            add_header Max-Age 0;
          '';
        };
        "/" = {
          return = "301 https://resumos.leic.pt$request_uri";
        };
      };
    };
  };
}
