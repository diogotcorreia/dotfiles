# Configuration that should be applied to all systems
{ profiles, ... }:
{
  imports = with profiles; [
    security.agenix
    services.ssh
    shell.programs.essential
  ];

  # Modern defaults
  networking.nftables.enable = true;
}
