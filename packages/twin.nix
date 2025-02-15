# Triton Web Interface
{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  stdenv,
  yarnBuildHook,
  yarnConfigHook,
  yarnInstallHook,
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

  frontend = stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "twin-frontend";
    src = "${commonSrc}/frontend";

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      sha256 = "sha256-sp3dbg0M/yWSgce1Sb8Ju6xHz6MUZVuEwLxyGicvDaM=";
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

    meta = meta';
  });

  backend = stdenv.mkDerivation (finalAttrs: {
    inherit version;
    pname = "twin-backend";
    src = "${commonSrc}/backend";

    yarnOfflineCache = fetchYarnDeps {
      yarnLock = finalAttrs.src + "/yarn.lock";
      sha256 = "sha256-4Hqsyq5tUIW6Swe5pq9ELLrHA8wViKO5NkCqKUQgqVQ=";
    };

    nativeBuildInputs = [
      yarnConfigHook
      yarnInstallHook
      makeWrapper
    ];

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
      OUT_JS_DIR="$out/lib/node_modules/${finalAttrs.pname}"

      makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
        --add-flags "$OUT_JS_DIR/src/index.js"

      # delete unnecessary files
      rm -r "$OUT_JS_DIR"/{config.def.js,migrations,upload,.prettierrc.json}
    '';

    meta =
      meta'
      // {
        mainProgram = "twin-backend";
      };
  });
in {
  inherit backend frontend;
}
