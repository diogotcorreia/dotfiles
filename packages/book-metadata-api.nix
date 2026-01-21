{
  chromium,
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  node-gyp,
  nodejs,
  pkg-config,
  pnpm,
  pnpmConfigHook,
  python3,
  stdenv,
  vips,
  ...
}:
let
  pin = {
    version = "3.3.1";
    srcHash = "sha256-UL2Pt6AxkcgghKnD4VStxU/09mu0tIuHPGt4RGB7ft0=";
    pnpmHash = "sha256-isco9zsgbzfG+nHvEXNiGoRaDxeRhIYzmrNsrw9oyec=";
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
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
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

  installPhase = ''
    runHook preInstall

    local -r packageOut="$out/lib/node_modules/$pname"

    pnpm --filter . deploy --prod --no-optional "$packageOut"

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
