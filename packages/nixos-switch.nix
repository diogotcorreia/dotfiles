# Utility script to fetch from my binary cache and switch to that configuration
{
  curl,
  lib,
  writeShellScriptBin,
  hostName ? null,
  ...
}:
let
  fetchFromCache = ''
    nix build --refresh --no-link -- "$config_store_path"
  '';
  setProfile = ''
    sudo nix-env -p /nix/var/nix/profiles/system --set "$config_store_path"
  '';
  switchToConfiguration = ''
    sudo systemd-run \
      -E LOCALE_ARCHIVE \
      -E NIXOS_INSTALL_BOOTLOADER= \
      --collect \
      --no-ask-password \
      --pipe \
      --quiet \
      --service-type=exec \
      --unit=nixos-rebuild-switch-to-configuration \
      --wait \
      "$config_store_path/bin/switch-to-configuration" \
      switch
  '';

  defaultBehavior = channel:
    if hostName == null then
      ''
        echo "Usage: $0 <store-path>" >&2
        exit 1
      ''
    else
      ''
        config_store_path="$(${lib.getExe curl} --url ${lib.escapeShellArg "https://infra-keyval.diogotc.com/${channel}nixos-system-${hostName}"})"
      '';

  hostnameRegex = if hostName == null then ".+" else hostName;
in
writeShellScriptBin "nixos-switch" ''
  set -e

  if [ $# -lt 1 ]; then
    ${defaultBehavior ""}
  elif [[ "$1" == "staging" ]]; then
    ${defaultBehavior "staging-"}
  else
    config_store_path="$1"
  fi

  if [[ ! "$config_store_path" =~ ^\/nix\/store\/[a-z0-9]{32}-nixos-system-${hostnameRegex}-[0-9]{2}\.[0-9]{2}\.[0-9]{8}\.[a-z0-9]{7,}$ ]]; then
    echo "fetched store path does not match expected format: $config_store_path"
    exit 1
  fi

  ${fetchFromCache}
  ${setProfile}
  ${switchToConfiguration}
''
