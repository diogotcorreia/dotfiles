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
  version = "2.7.0";
  pname = "bentopdf";

  src = fetchFromGitHub {
    owner = "alam00000";
    repo = "bentopdf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mOM3NaXg3JVrNq8f4f7s/EkAitKn+3Gql3T4RzglpF0=";
  };
  npmDepsHash = "sha256-YElNw5wR9+kZpZ2+0QqeedtJQEmlycFTO2Q6qplhv0U=";

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
