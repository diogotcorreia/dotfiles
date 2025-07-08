{lib, ...}: {
  # Replaces /var/lib with /var/lib/private in a path.
  # Usage: `toPrivateStateDirectory "/var/lib/<name>/<...>"`
  toPrivateStateDirectory = path: "/var/lib/private/${lib.removePrefix "/var/lib/" path}";
}
