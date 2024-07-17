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
  version = "unstable-2021-11-26";
  src = fetchFromGitHub {
    owner = "tritonmc";
    repo = "triton-bot";
    rev = "f93610e38fa656fe6402e50ace75a8ee51164175";
    hash = "sha256-QC/RpdbPQLnk5gQVXAIadMMoPVvPDJ+a9JtqLqlS118=";
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
