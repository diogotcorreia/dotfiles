# Fix systemd dbus timeout reached when switching configuration
# See https://github.com/NixOS/nixpkgs/issues/378535
{...}: final: prev: {
  switch-to-configuration-ng = prev.switch-to-configuration-ng.overrideAttrs (oldAttrs: {
    patches = [
      # https://github.com/NixOS/nixpkgs/pull/476759
      ./0001-switch-to-configuration-ng-fix-systemd-reexec-reload.patch

      ./0002-add-extra-debug-logs.diff
    ];
  });
}
