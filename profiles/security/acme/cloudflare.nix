# Configure lego to use cloudflare dns for certificate challenges
{
  config,
  profiles,
  secrets,
  ...
}: {
  imports = with profiles; [
    security.acme.common
  ];

  age.secrets.acmeCloudflareToken.file = secrets.host.cloudflareToken;

  security.acme = {
    defaults = {
      dnsProvider = "cloudflare";
      credentialFiles = {
        CLOUDFLARE_DNS_API_TOKEN_FILE = config.age.secrets.acmeCloudflareToken.path;
      };
    };
  };
}
