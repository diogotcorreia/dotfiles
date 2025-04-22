# Configuration that should be applied to all systems
{profiles, ...}: {
  imports = with profiles; [
    services.ssh
    shell.programs.essential
  ];
}
