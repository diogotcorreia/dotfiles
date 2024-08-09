# Common configuration for lego
{config, ...}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "${config.networking.hostName}-lets-encrypt@${config.networking.domain}";
    };
  };

  modules.impermanence.directories = [
    "/var/lib/acme"
  ];
}
