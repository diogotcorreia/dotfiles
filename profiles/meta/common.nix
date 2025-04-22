# Configuration that should be applied to all systems
{profiles, ...}: {
  imports = with profiles; [
    security.hotfix-cve-2025-32438
    services.ssh
    shell.programs.essential
  ];
}
