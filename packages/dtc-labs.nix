# Miscellaneous web services by me
{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  makeWrapper,
  nodejs,
  stdenv,
  yarnConfigHook,
  yarnInstallHook,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dtc-labs";
  version = "2.0.1";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mYrha328sxYwUXDi5tsuMsuxVm3JZfkk1YZ1GfRNzSs=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    sha256 = "sha256-6+PYPUjK9IzhLHksZNoLMYQ8XgzerOWYGZW5hbm3nW8=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnInstallHook
    makeWrapper
    nodejs
  ];

  postInstall = ''
    OUT_JS_DIR="$out/lib/node_modules/${finalAttrs.pname}"

    # yarnInstallHook copies everything over already

    # generate binary
    makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
      --add-flags "$OUT_JS_DIR/src/index.js"

    # delete unnecessary files
    rm -r "$OUT_JS_DIR"/{package.json,README.md,.prettierrc,LICENSE,.husky,renovate.json,shell.nix}
  '';

  meta = with lib; {
    description = "Experimental code snippets for DTC";
    homepage = "https://github.com/diogotcorreia/dtc-labs";
    license = licenses.gpl3Plus;
    mainProgram = "dtc-labs";
    platforms = platforms.all;
  };
})
