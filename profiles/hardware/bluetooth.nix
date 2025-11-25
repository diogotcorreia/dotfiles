# Enables bluetooth and related TUI
{ pkgs, ... }:
{
  # Enable bluetooth stack
  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    # Enable bluetooth TUI
    bluetui
  ];

  # Preserve paired devices across reboots (on root-on-tmpfs systems)
  modules.impermanence.directories = [
    "/var/lib/bluetooth"
  ];
}
