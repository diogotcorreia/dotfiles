# Battleships game
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  ...
}: let
  version = "0-unstable-2025-02-02";
  commonSrc = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "battleship-js";
    rev = "235ac39e79ae033304f1d073044de8a14ec31be4";
    hash = "sha256-MhzeCt002bZ2Rc7pHKK6W+BKLc11S8NRyZtX2+S3TtI=";
  };
  meta' = with lib; {
    description = "A Battleship game made for the web";
    homepage = "https://github.com/diogotcorreia/battleship-js";
    license = licenses.mit;
    platforms = platforms.all;
  };

  client = mkYarnPackage rec {
    inherit version;
    pname = "battleship-js-client";
    src = "${commonSrc}/client";

    buildPhase = ''
      runHook preBuild

      yarn --offline build

      runHook postBuild
    '';

    # get rid of everything except for build result
    postInstall = ''
      cp -r $out/${passthru.nodeAppDir}/build $out
      rm -rf $out/bin $out/libexec
    '';

    # error:0308010C:digital envelope routines::unsupported
    NODE_OPTIONS = "--openssl-legacy-provider";

    # don't generate the dist tarball
    doDist = false;

    env.REACT_APP_SOCKET_URL = "/";

    passthru = {
      nodeAppDir = "libexec/${pname}/deps/${pname}";
    };

    meta = meta';
  };

  server = mkYarnPackage rec {
    inherit version;
    pname = "battleship-js";
    src = commonSrc;

    nativeBuildInputs = [makeWrapper];

    prePatch = ''
      rm -rf client
    '';

    # Prevent server from serving files (let nginx do that instead)
    patchPhase = ''
      runHook prePatch

      substituteInPlace src/server.js \
        --replace-fail "process.env.NODE_ENV === 'production'" "false"

      runHook postPatch
    '';

    # generate binary
    postInstall = ''
      OUT_JS_DIR="$out/${passthru.nodeAppDir}"

      makeWrapper '${lib.getExe nodejs}' "$out/bin/${pname}" \
        --set NODE_ENV production \
        --add-flags "$OUT_JS_DIR/src/server.js"

      # delete unnecessary files
      rm -rf "$out/${passthru.nodeAppDir}/"{.gitignore,.prettierrc,README.md,default.env,yarn.lock}
    '';

    # there are no tests :/
    doCheck = false;
    # don't generate the dist tarball
    doDist = false;

    passthru = {
      nodeAppDir = "libexec/${pname}/deps/${pname}";
    };

    meta =
      meta'
      // {
        mainProgram = pname;
      };
  };
in {
  inherit client server;
}
