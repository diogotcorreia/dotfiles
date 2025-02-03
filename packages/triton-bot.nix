# Bot for Triton's Discord server
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  ...
}:
mkYarnPackage rec {
  pname = "triton-bot";
  version = "0-unstable-2025-02-03";
  src = fetchFromGitHub {
    owner = "tritonmc";
    repo = "triton-bot";
    rev = "1b273a1ca80079cb3d1c9d23291b53220d2d49b9";
    hash = "sha256-J5KMhrQWFoCOCNRr+LJ7VGry5ljGcR7ZkSuzVo6RMDU=";
  };

  nativeBuildInputs = [makeWrapper];

  buildPhase = ''
    runHook preBuild

    yarn --offline build

    runHook postBuild
  '';

  # generate binary
  postInstall = ''
    OUT_JS_DIR="$out/${passthru.nodeAppDir}/dist"

    makeWrapper '${lib.getExe nodejs}' "$out/bin/${pname}" \
      --add-flags "$OUT_JS_DIR/index.js"

    # delete unnecessary files
    rm -rf "$out/${passthru.nodeAppDir}/"{knexfile.js,migrations,package.json,README.md,src,yarn.lock}
  '';

  # there are no tests :/
  doCheck = false;
  # don't generate the dist tarball
  doDist = false;

  passthru = {
    nodeAppDir = "libexec/${pname}/deps/${pname}";
  };

  meta = with lib; {
    description = "Bot for TritonMC's Discord server";
    homepage = "https://github.com/tritonmc/triton-bot";
    license = licenses.free;
    mainProgram = "triton-bot";
    platforms = platforms.all;
  };
}
