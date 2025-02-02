# Peer-to-peer file transfers web app
{pkgs, ...}: let
  domain = "drop.diogotc.com";
  port = 2326;
in {
  services.pairdrop = {
    enable = true;
    # TODO 25.05: use stable package
    package = pkgs.my.pairdrop;

    inherit port;

    settings = {
      RTC_CONFIG = {
        sdpSemantics = "unified-plan";
        iceServers = [
          {
            urls = "stun:stun.l.google.com:19302";
          }
        ];
      };
      RATE_LIMIT = 1;
      IPV6_LOCALIZE = 4;
      WS_FALLBACK = true;

      DONATION_BUTTON_ACTIVE = false;
      TWITTER_BUTTON_ACTIVE = false;
      MASTODON_BUTTON_ACTIVE = false;
      BLUESKY_BUTTON_ACTIVE = false;
      CUSTOM_BUTTON_ACTIVE = false;
      PRIVACYPOLICY_BUTTON_ACTIVE = false;
    };
  };

  services.nginx.virtualHosts = {
    ${domain} = {
      enableACME = true;
      enableCloudflareRealIp = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString port}";
    };
  };
}
