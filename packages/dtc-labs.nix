# Miscellaneous web services by me
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  ...
}:
mkYarnPackage rec {
  pname = "dtc-labs";
  version = "0-unstable-2025-02-03";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "4deae8c1d25570dcd7f49088c277da65a2c8705f";
    hash = "sha256-DKu/7feLmicEO9aMvFsghzMH7JlliU9DR3fr2HcwyVY=";
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
    rm -rf "$out/${passthru.nodeAppDir}/"{src,package.json,README.md,yarn.lock}
  '';

  # there are no tests :/
  doCheck = false;
  # don't generate the dist tarball
  doDist = false;

  passthru = {
    nodeAppDir = "libexec/${pname}/deps/${pname}";
  };

  meta = with lib; {
    description = "Experimental code snippets for DTC";
    homepage = "https://github.com/diogotcorreia/dtc-labs";
    license = licenses.free;
    mainProgram = "dtc-labs";
    platforms = platforms.all;
  };
}
