# Triton Web Interface
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  ...
}: let
  version = "unstable-2024-02-28";
  commonSrc = fetchFromGitHub {
    owner = "tritonmc";
    repo = "twin";
    rev = "02d89cf5cee86e206bc8255d0b688cea25f16287";
    hash = "sha256-4jaJzGL2r2qnNsvfnDzyEDgnOFMjYr7+VERpxpI6sQA=";
  };
  meta = with lib; {
    description = "Web interface for TritonMC plugin";
    homepage = "https://github.com/tritonmc/twin";
    license = licenses.gpl3;
    platforms = platforms.all;
  };

  frontend = mkYarnPackage rec {
    inherit meta version;
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
  };

  backend = mkYarnPackage rec {
    inherit meta version;
    pname = "twin-backend";
    src = "${commonSrc}/backend";

    nativeBuildInputs = [makeWrapper];

    # Setup config and patch upload folder to be outside the nix store
    patchPhase = ''
      runHook prePatch

      cat <<EOF > config.js
      export default {
        disableDatabase: !!process.env.DISABLE_DATABASE,
        database: {
          host: process.env.DB_HOST ?? "localhost",
          port: parseInt(process.env.DB_PORT ?? 3306, 10),
          user: process.env.DB_USER ?? "root",
          password: process.env.DB_PASSWORD ?? "",
          database: process.env.DB_NAME ?? "triton",
        },
        fileExpiry: 24 * 60 * 60 * 1000, // 24h
        disabledModules: [],
      };
      EOF

      substituteInPlace src/storage.js \
        --replace-fail "const __dirname = path.dirname(fileURLToPath(import.meta.url));" "const __dirname = process.env.STATE_DIR || '.';"

      runHook postPatch
    '';

    # generate binary
    postInstall = ''
      OUT_JS_DIR="$out/${passthru.nodeAppDir}"

      makeWrapper '${lib.getExe nodejs}' "$out/bin/${pname}" \
        --add-flags "$OUT_JS_DIR/src/index.js"
    '';

    # there are no tests :/
    doCheck = false;
    # don't generate the dist tarball
    doDist = false;

    passthru = {
      nodeAppDir = "libexec/${pname}/deps/${pname}";
    };
  };
in {
  inherit backend frontend;
}
