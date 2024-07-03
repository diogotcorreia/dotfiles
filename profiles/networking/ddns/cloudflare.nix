{
  config,
  secrets,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) escapeShellArgs getExe;

  records = [
    "world.${config.networking.hostName}.${config.networking.domain}"
  ];
in {
  systemd.services.cloudflare-ddns = {
    description = "CloudFlare Dynamic DNS Client";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    startAt = "*:0/5";
    serviceConfig = {
      Type = "simple";
      LoadCredential = "CLOUDFLARE_API_TOKEN_FILE:${config.age.secrets."cloudflareToken".path}";
      DynamicUser = true;
    };
    script = ''
      export CLOUDFLARE_API_TOKEN=$(${pkgs.systemd}/bin/systemd-creds cat CLOUDFLARE_API_TOKEN_FILE)
      ${getExe pkgs.my.cloudflare-ddns} ${escapeShellArgs records}
    '';
  };

  age.secrets."cloudflareToken".file = secrets.host.cloudflareToken;
}
