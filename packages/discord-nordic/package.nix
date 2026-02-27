{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  nodejs,
  pnpm,
  pnpmConfigHook,
  stdenv,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "discord-nordic";
  version = "4.13.1";

  src = fetchFromGitHub {
    owner = "orblazer";
    repo = "discord-nordic";
    tag = "v${finalAttrs.version}";
    hash = "sha256-oAK3MY23U0BUFYTXpeE+VByFwRZiGFk6/K7zZrWwv0o=";
  };

  patches = [
    ./0001-embed-images.diff
  ];

  # delete already built artifacts
  postPatch = ''
    rm *.css
  '';

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
    hash = "sha256-oCdJNX/bft8OFNw+KbizfsDgY03iTcISEjqshJNcZWQ=";
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
