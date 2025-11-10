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
  version = "0-unstable-2025-11-10";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "065cde59a779a08028815e820e25a1e8ac1a1eb0";
    hash = "sha256-rRE+xRFuV2vw01AAuLOeVVMlBTI5yfZkuE9Jn+I4mow=";
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
