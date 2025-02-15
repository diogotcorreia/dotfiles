# Bot for Triton's Discord server
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
  pname = "triton-bot";
  version = "0-unstable-2025-02-03";
  src = fetchFromGitHub {
    owner = "tritonmc";
    repo = "triton-bot";
    rev = "1b273a1ca80079cb3d1c9d23291b53220d2d49b9";
    hash = "sha256-J5KMhrQWFoCOCNRr+LJ7VGry5ljGcR7ZkSuzVo6RMDU=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    sha256 = "sha256-zKMsilmfUM9HhweGhXFn0bpAhITA6Tnmovl13uohZ3I=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    makeWrapper
    nodejs
  ];

  # generate binary
  postInstall = ''
    OUT_JS_DIR="$out/lib/node_modules/${finalAttrs.pname}"

    cp -r dist "$OUT_JS_DIR"

    makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
      --add-flags "$OUT_JS_DIR/dist/index.js"

    # delete unnecessary files
    rm -r "$OUT_JS_DIR"/{knexfile.js,migrations,package.json,README.md,src,.husky,.prettierrc,.babelrc}
  '';

  meta = with lib; {
    description = "Bot for TritonMC's Discord server";
    homepage = "https://github.com/tritonmc/triton-bot";
    license = licenses.free;
    mainProgram = "triton-bot";
    platforms = platforms.all;
  };
})
