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
  version = "0-unstable-2026-01-20";
  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "dtc-labs";
    rev = "bc7d557e772d256ef3036ff96132fe6181bd2a14";
    hash = "sha256-w8DWAbdlp23mJofVK6ynBsGOFE/o2W86poq3ZtLxGPY=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    sha256 = "sha256-cytlWPIa6sWsJxvu+iOF12spdGEehMuSCR0EFCRscFI=";
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
