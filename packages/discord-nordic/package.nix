{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenv,
  ...
}:
let
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "discord-nordic";
  version = "4.13.2";

  src = fetchFromGitHub {
    owner = "orblazer";
    repo = "discord-nordic";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bzRRRSbIUAaSX6tHaq8n5MeKi4xSpPdvq1RfBLebqBo=";
  };

  patches = [
    ./0001-embed-images.diff
  ];

  # delete already built artifacts
  postPatch = ''
    rm *.css
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit pnpm;
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
    hash = "sha256-wfFETcjzpF+ZjAsRqgn3OrS1hJ22a3uTI4f4NQbJlMk=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild

    node ./src/scripts/build.js

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp *.css "$out"

    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/orblazer/discord-nordic/blob/v${finalAttrs.version}/CHANGELOG.md";
    description = "A full themed discord with Nord palette";
    homepage = "https://github.com/orblazer/discord-nordic";
    license = lib.licenses.cc-by-nc-sa-40;
    maintainers = with lib.maintainers; [ diogotcorreia ];
  };
})
