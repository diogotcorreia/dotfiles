# Upgrade to v3.0.2/v3.0.3 to fix critical CVE
# https://github.com/NixOS/nixpkgs/pull/467820
{ ... }:
(_: prev: {
  umami = prev.umami.overrideAttrs (oldAttrs: rec {
    version = "3.0.3";
    src = prev.fetchFromGitHub {
      owner = "umami-software";
      repo = "umami";
      tag = "v3.0.3";
      hash = "sha256-rkOD52suE6bihJqKvMdIvqHRIcWhSxXzUkCfmdNbC40=";
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
      hash = "sha256-eXurT8kfVJcJoFunrt7h8LKuhsIhGrYDW6shvGA6GXY=";
    };
  });
})
