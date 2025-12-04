# Upgrade to v3.0.2 to fix critical CVE
# https://github.com/NixOS/nixpkgs/pull/467820
{ ... }:
(_: prev: {
  umami = prev.umami.overrideAttrs (oldAttrs: rec {
    version = "3.0.2";
    src = prev.fetchFromGitHub {
      owner = "umami-software";
      repo = "umami";
      tag = "v3.0.2";
      hash = "sha256-6ega3ShfZlEnoFuFSh420hB8sp2qoJuAYnzeoOdpODs=";
    };
    pnpmDeps = prev.pnpm_10.fetchDeps {
      inherit (oldAttrs)
        pname
        pnpmInstallFlags
        ;
      inherit
        version
        src
        ;
      fetcherVersion = 2;
      hash = "sha256-zHpIqhxfvJ/so7bKvrGMqVGGnquJNnSI/0q3PE+VQ1Y=";
    };

    DATABASE_URL = "postgresql://";
  });
})
