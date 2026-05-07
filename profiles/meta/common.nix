# Configuration that should be applied to all systems
{ profiles, ... }:
{
  imports = with profiles; [
    security.agenix
    services.ssh
    shell.fish
    shell.programs.essential
  ];

  # Modern defaults
  networking.nftables.enable = true;

  # Mitigation for dirtyfrag vulnerability
  boot.extraModprobeConfig = ''
    install esp4 /bin/false
    install esp6 /bin/false
    install rxrpc /bin/false
  '';
}
