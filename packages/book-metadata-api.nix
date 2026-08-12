{
  chromium,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  node-gyp,
  nodejs,
  pkg-config,
  pnpm_11,
  pnpmConfigHook,
  python3,
  stdenv,
  vips,
  ...
}:
let
  pnpm = pnpm_11;
  pin = {
    version = "3.4.2";
    srcHash = "sha256-xGsGjVytFFivpyH6Q6KE1wszzroHSNuyIAwgY2+Nv9o=";
    pnpmHash = "sha256-689pH/8c2vVFUaz1GopP/9bdtdp6z385X+BGcFMMEr8=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "book-metadata-api";
  inherit (pin) version;

  src = fetchFromGitHub {
    owner = "livraria-papelaria-espaco";
    repo = "book-metadata-api";
    tag = "v${finalAttrs.version}";
    hash = pin.srcHash;
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pnpm;
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 4;
    hash = pin.pnpmHash;
  };

  buildInputs = [
    vips
  ];

  nativeBuildInputs = [
    chromium
    makeWrapper
    node-gyp
    nodejs
    pkg-config
    pnpm
    pnpmConfigHook
    python3
  ];

  env.SHARP_FORCE_GLOBAL_LIBVIPS = 1;
  # fix for node-gyp, see https://github.com/nodejs/node-gyp/issues/1191#issuecomment-301243919
  env.npm_config_nodedir = nodejs;

  preBuild = ''
    # Force build of sharp against native libvips (requires running install scripts).
    npm explore sharp -- pnpm run build
  '';

  installPhase = ''
    runHook preInstall

    local -r packageOut="$out/lib/node_modules/$pname"

    pnpm --filter . deploy --prod --no-optional "$packageOut"
    # pnpm deploy does not copy the built sharp libs, so we copy them manually
    mv node_modules/sharp/src/build "$packageOut"/node_modules/sharp/src

    # remove build artifacts that bloat the closure
    find "$packageOut/node_modules" \( \
      -name config.gypi \
      -o -name .deps \
      -o -name '*Makefile' \
      -o -name '*.target.mk' \
    \) -exec rm -r {} +
    rm "$packageOut/pnpm-lock.yaml"

    makeWrapper '${nodejs}/bin/node' "$out/bin/book-metadata-api" \
      --add-flags "$packageOut/src/index.js" \
      --set PUPPETEER_SKIP_DOWNLOAD 1 \
      --set PUPPETEER_EXECUTABLE_PATH ${lib.getExe chromium}

    runHook postInstall
  '';

  meta = {
    mainProgram = "book-metadata-api";
  };
})
