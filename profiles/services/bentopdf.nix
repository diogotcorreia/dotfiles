{ pkgs, ... }:
let
  domain = "pdf.diogotc.com";
in
{
  services.nginx.virtualHosts."${domain}" = {
    enableACME = true;
    # TODO 26.11: use package from stable
    root = pkgs.unstable.bentopdf;

    locations."/" = {
      index = "index.html";
      extraConfig = ''
        try_files $uri $uri/ /index.html;
      '';
    };

    locations."~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$".extraConfig = ''
      expires 1y;
      add_header Cache-Control "public, immutable";
    '';
  };
}
