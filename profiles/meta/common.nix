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

  # Hotfix for root certificate compromise
  # https://emudhra.we-have-a-problem.com/
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
