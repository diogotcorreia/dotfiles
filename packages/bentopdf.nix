{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  prefetch-npm-deps-patched,
  npmHooks,
  simpleMode ? true,
}:
let
  buildNpmPackage' = buildNpmPackage.override (prev: {
    fetchNpmDeps = prev.fetchNpmDeps.override {
      prefetch-npm-deps = prefetch-npm-deps-patched;
    };
  });
  npmHooks' = npmHooks.override {
    prefetch-npm-deps = prefetch-npm-deps-patched;
  };
in
buildNpmPackage' (finalAttrs: {
  version = "1.16.1";
  pname = "bentopdf";

  src = fetchFromGitHub {
    owner = "alam00000";
    repo = "bentopdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-34Q7eAYIgAGdTaz4eh0OcMTUuuMm293rAb+/GUOIxBA=";
  };
  npmDepsHash = "sha256-w/xeZQYUBUIqAkv77YZeCww32AgYYQ+JSAhUmMhQQPA=";

  npmBuildScript = "build";
  npmBuildFlags = [
    "--"
    "--mode"
    "production"
  ];

  inherit (npmHooks') npmConfigHook;

  env.SIMPLE_MODE = lib.boolToString simpleMode;

  makeCacheWritable = true;

  installPhase = ''
    runHook preInstal

    mkdir -p $out
    cp -r dist/* $out/

    runHook postInstall
  '';

  meta = {
    description = "Privacy-first PDF toolkit";
    homepage = "https://bentopdf.com";
    changelog = "https://github.com/alam00000/bentopdf/releases";
    license = lib.licenses.agpl3Only;
  };
})
