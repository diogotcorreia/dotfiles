# Triton Web Interface
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  ...
}: let
  version = "0-unstable-2025-02-03";
  commonSrc = fetchFromGitHub {
    owner = "tritonmc";
    repo = "twin";
    rev = "29cdd28c0b329e26bdad0a5682c20df27ed07672";
    hash = "sha256-gF/xcWIj0VRnsF9hRmlGgU76cd2+IuYCViwYF88WyhY=";
  };
  meta' = with lib; {
    description = "Web interface for TritonMC plugin";
    homepage = "https://github.com/tritonmc/twin";
    license = licenses.gpl3;
    platforms = platforms.all;
  };

  frontend = mkYarnPackage rec {
    inherit version;
    pname = "twin-frontend";
    src = "${commonSrc}/frontend";

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

    passthru = {
      nodeAppDir = "libexec/twin/deps/twin";
    };

    meta = meta';
  };

  backend = mkYarnPackage rec {
    inherit version;
    pname = "twin-backend";
    src = "${commonSrc}/backend";

    nativeBuildInputs = [makeWrapper];

    # Setup config and patch upload folder to be outside the nix store
    patchPhase = ''
      runHook prePatch

      cat <<EOF > config.js
      export default {
        disableDatabase: !!process.env.DISABLE_DATABASE,
        database: process.env.DB_URL ?? "postgresql:///triton?host=/run/postgresql",
        fileExpiry: 24 * 60 * 60 * 1000, // 24h
        disabledModules: [],
      };
      EOF

      substituteInPlace src/storage.js \
        --replace-fail "const __dirname = path.dirname(fileURLToPath(import.meta.url));" "const __dirname = process.env.STATE_DIR || '.';" \
        --replace-fail "../upload" "./upload"

      runHook postPatch
    '';

    # generate binary
    postInstall = ''
      OUT_JS_DIR="$out/${passthru.nodeAppDir}"

      makeWrapper '${lib.getExe nodejs}' "$out/bin/${pname}" \
        --add-flags "$OUT_JS_DIR/src/index.js"

      # delete unnecessary files
      rm -rf "$out/${passthru.nodeAppDir}/"{config.def.js,migrations,upload,yarn.lock,.prettierrc.json}
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
        mainProgram = "twin-backend";
      };
  };
in {
  inherit backend frontend;
}
