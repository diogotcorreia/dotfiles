# Fix systemd dbus timeout reached when switching configuration
# See https://github.com/NixOS/nixpkgs/issues/378535
{...}: final: prev: {
  switch-to-configuration-ng = prev.switch-to-configuration-ng.overrideAttrs (oldAttrs: {
    patches = [
      ./0001-add-extra-debug-logs.diff
    ];
  });
}
