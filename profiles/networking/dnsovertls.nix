# Configure systemd-resolved to use DNS over TLS
{
  config,
  ...
}:
let
  upstream = [
    # cloudflare
    "1.1.1.1#cloudflare-dns.com"
    "2606:4700:4700::1111#cloudflare-dns.com"

  ];
  fallback = [
    # cloudflare
    "1.0.0.1#cloudflare-dns.com"
    "2606:4700:4700::1001#cloudflare-dns.com"

    # mullvad
    "194.242.2.2#dns.mullvad.net"
    "2a07:e340::2#dns.mullvad.net"

    # quad9
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"

    # google
    "8.8.8.8#dns.google"
    "8.8.4.4#dns.google"
    "2001:4860:4860::8888#dns.google"
    "2001:4860:4860::8844#dns.google"
  ];
in
{
  networking.nameservers = upstream;

  services.resolved = {
    enable = true;
    dnsovertls = "true";
    dnssec = "true";
    extraConfig = ''
      Cache=yes
      DNSSEC=yes
    '';
    fallbackDns = fallback;
    domains = config.networking.search ++ [ "~." ]; # Force all queries to use the dnsproxy
  };
}
