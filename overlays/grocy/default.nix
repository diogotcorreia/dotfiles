# overlays/grocy.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Update grocy to 4.0.2

{ inputs, ... }:
final: prev: rec {
  # TODO temporary until https://github.com/NixOS/nixpkgs/pull/250224 is merged

  grocy = prev.grocy.overrideAttrs (old: rec {
    version = "4.0.2";
    src = builtins.fetchurl {
      url =
        "https://github.com/grocy/grocy/releases/download/v${version}/grocy_${version}.zip";
      sha256 = "sha256-ZhXfZKmfg8lSzEAGIj7LMIfvaHG1FY5j+/OpOCTxm3c=";
    };

    # otherwise the package will use the original src
    unpackPhase = ''
      unzip ${src} -d .
    '';

    patches = [
      ./0001-Define-configs-with-env-vars.patch
      ./0002-Remove-check-for-config-file-as-it-s-stored-in-etc-g.patch
    ];
  });
}
