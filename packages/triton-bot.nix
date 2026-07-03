# Bot for Triton's Discord server
{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenv,
  ...
}:
let
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "triton-bot";
  version = "4.0.1";
  src = fetchFromGitHub {
    owner = "tritonmc";
    repo = "triton-bot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WebnfxVdwknZzWhrXsHWTAjBPUdM9KM5IOdkCbHb/0E=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pnpm;
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
    hash = "sha256-Xf6sv2f9Id06fdRl1+xxULlaUWJqA0UYJRNwbhB8UxQ=";
  };

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    makeWrapper
    nodejs
  ];

  installPhase = ''
    runHook preInstall

    local -r packageOut="$out/lib/node_modules/$pname"

    pnpm --filter . deploy --prod --no-optional "$packageOut"

    # remove files that bloat the closure
    rm "$packageOut"/{pnpm-lock.yaml,LICENSE,package.json,README.md}

    makeWrapper '${lib.getExe nodejs}' "$out/bin/${finalAttrs.pname}" \
      --add-flags "$packageOut/src/index.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Bot for TritonMC's Discord server";
    homepage = "https://github.com/tritonmc/triton-bot";
    license = licenses.gpl3Plus;
    mainProgram = "triton-bot";
    platforms = platforms.all;
  };
})
