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
  version = "unstable-2023-05-06";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "d076b9b18aca840ea265382ae754e45c86ebf805";
    hash = "sha256-MLt3JFsU+Y6VmOx7aXjKb52SAX/qCDwS4NUcPcBQCec=";
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
    description = "Experimental code snippets for DTC";
    homepage = "https://github.com/diogotcorreia/dtc-labs";
    license = licenses.free;
    mainProgram = "dtc-labs";
    platforms = platforms.all;
  };
}
