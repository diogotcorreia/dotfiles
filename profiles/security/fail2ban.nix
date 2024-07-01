# Fail2ban configuration
{...}: {
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "192.168.100.0/24" # Nebula network
    ];
  };
}
