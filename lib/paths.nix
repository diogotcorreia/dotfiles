{lib, ...}: {
  # Replaces /var/lib with /var/lib/private in a path.
  # Usage: `realPathOfSystemdState "/var/lib/<name>/<...>"`
  toPrivateStateDirectory = path: "/var/lib/private/${lib.removePrefix "/var/lib/" path}";
}
