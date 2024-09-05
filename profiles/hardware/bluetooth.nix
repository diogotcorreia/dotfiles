# Enables bluetooth and related TUI
{pkgs, ...}: {
  # Enable bluetooth stack
  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    # Enable bluetooth TUI
    bluetuith
  ];

  hm.xdg.configFile."bluetuith/bluetuith.conf".source = pkgs.writers.writeJSON "bluetuith.conf" {
    # Disable OBEX warning on startup
    no-warning = true;
  };

  # Preserve paired devices across reboots (on root-on-tmpfs systems)
  modules.impermanence.directories = [
    "/var/lib/bluetooth"
  ];
}
