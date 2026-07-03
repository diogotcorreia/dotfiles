# Miscellaneous web services by me
{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  makeWrapper,
  nodejs,
  stdenv,
  yarnConfigHook,
  yarnInstallHook,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "dtc-labs";
  version = "0-unstable-2026-07-03";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "f534222cfd9e0d301b2581dddb72fec7a181ba98";
    hash = "sha256-IGxnFlLeJ+Ls0g2P4Bjr58DRIeerPZTY8khbrzXT/kU=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    sha256 = "sha256-EV4npvscp2GF4RYHA+5fl4kmwbCw8Oyc4K4YHs1Bz+U=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnInstallHook
    makeWrapper
    nodejs
  ];

  postInstall = ''
    OUT_JS_DIR="$out/lib/node_modules/${finalAttrs.pname}"

    # yarnInstallHook copies everything over already

    # generate binary
    makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
      --add-flags "$OUT_JS_DIR/src/index.js"

    # delete unnecessary files
    rm -r "$OUT_JS_DIR"/{package.json,README.md,.prettierrc,LICENSE,.husky,renovate.json,shell.nix}
  '';

  meta = with lib; {
    description = "Experimental code snippets for DTC";
    homepage = "https://github.com/diogotcorreia/dtc-labs";
    license = licenses.gpl3Plus;
    mainProgram = "dtc-labs";
    platforms = platforms.all;
  };
})
