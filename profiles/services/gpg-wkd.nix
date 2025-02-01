# Server GPG WKD static directory
{pkgs, ...}: {
  services.nginx.virtualHosts = {
    "gpg.diogotc.com" = {
      serverAliases = ["openpgpkey.diogotc.com"];
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/" = {
        root = pkgs.my.gpg-wkd;
        index = "diogo.gpg.asc";
      };
    };
  };
}
