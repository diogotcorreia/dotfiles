# Battleships game
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
let
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

  client = stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "battleship-js-client";
    src = "${commonSrc}/client";

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      sha256 = "sha256-iMhM1vzRGxO+0EpLXj87yeUUz1W8Yj6utT+Exalu/f0=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];

    # get rid of everything except for build result
    postInstall = ''
      mkdir -p $out
      cp -r build $out
    '';

    # error:0308010C:digital envelope routines::unsupported
    env.NODE_OPTIONS = "--openssl-legacy-provider";
    env.REACT_APP_SOCKET_URL = "/";

    meta = meta';
  });

  server = stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "battleship-js";
    src = commonSrc;

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      sha256 = "sha256-DVaocTy3WOmkJm9fKfSgcqCN/y7+hhUXfGpi0HXsCeU=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnInstallHook
      makeWrapper
    ];

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
      OUT_JS_DIR="$out/lib/node_modules/battleship-js"

      makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
        --set NODE_ENV production \
        --add-flags "$OUT_JS_DIR/src/server.js"

      # delete unnecessary files
      rm "$OUT_JS_DIR"/{.prettierrc,README.md,default.env}
    '';

    meta = meta' // {
      mainProgram = finalAttrs.pname;
    };
  });
in
{
  inherit client server;
}
