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
  version = "2.8.4";
  pname = "bentopdf";

  src = fetchFromGitHub {
    owner = "alam00000";
    repo = "bentopdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kVCzIFINN+Qs4TfLMqon8A9mQQ8kCRqdmu1CrzaRqf0=";
  };
  npmDepsHash = "sha256-TWfCuYRQWDhMhCrUXcSZ54yb6BAAYGiJBhZoCHLYtcs=";

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
