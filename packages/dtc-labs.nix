# Miscellaneous web services by me
{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  makeWrapper,
  nodejs,
  stdenv,
  yarnBuildHook,
  yarnConfigHook,
  yarnInstallHook,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dtc-labs";
  version = "0-unstable-2025-02-15";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "c31d6b5538d040bc79c420a2ea2ce0e9df6a93f6";
    hash = "sha256-OyyjzjsZ0KgljSqZxkMJEc8qD1FrDsWoFmRf2nwR+QE=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    sha256 = "sha256-A3HDyDqJh3RBSgABaC4sl0RHWmcujLaU6i7ML4RAPdc=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    makeWrapper
    nodejs
  ];

  postInstall = ''
    OUT_JS_DIR="$out/lib/node_modules/${finalAttrs.pname}"

    cp -r dist "$OUT_JS_DIR"

    # generate binary
    makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
      --add-flags "$OUT_JS_DIR/dist/index.js"

    # delete unnecessary files
    rm -r "$OUT_JS_DIR"/{src,package.json,README.md,.babelrc,.prettierrc}
  '';

  meta = with lib; {
    description = "Experimental code snippets for DTC";
    homepage = "https://github.com/diogotcorreia/dtc-labs";
    license = licenses.free;
    mainProgram = "dtc-labs";
    platforms = platforms.all;
  };
})
