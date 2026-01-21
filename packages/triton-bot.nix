# Bot for Triton's Discord server
{
  fetchFromGitHub,
  fetchPnpmDeps,
  lib,
  makeWrapper,
  nodejs,
  pnpm,
  pnpmConfigHook,
  stdenv,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "triton-bot";
  version = "4.0.0";
  src = fetchFromGitHub {
    owner = "tritonmc";
    repo = "triton-bot";
    tag = "v${finalAttrs.version}";
    hash = "sha256-H2U/7A3rvKqaCqjOwHEctWN1a8BgNMyqG9FoA5QGxOg=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    fetcherVersion = 3;
    hash = "sha256-kvBJOfjj9GIjJBPbplnh812r0puYYWVe06Lbz7c29Vk=";
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
