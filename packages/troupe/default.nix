{
  buildNpmPackage,
  fetchFromGitHub,
  haskellPackages,
  lib,
  nodejs,
  typescript,
  writeScript,
  ...
}: let
  version = "unstable-2024-02-19";

  src = fetchFromGitHub {
    owner = "TroupeLang";
    repo = "Troupe";
    rev = "0dea01aee6497e14c563ea8983830a53d5d8719c";
    hash = "sha256-X/jas6dL1OqXRqYNmRsxj8Fxssm7G+AYFXBk4h477jY=";
  };

  runtimeWrapper = writeScript "troupe" ''
    export TROUPE=@troupe@
    file="$1"
    shift

    ${lib.getExe nodejs} --stack-trace-limit=1000 @troupe_rt@ -f="$file" "$@"
  '';

  troupeRuntime = buildNpmPackage {
    inherit src version;
    pname = "troupe-runtime";

    buildInputs = [
      troupeCompiler
    ];

    postPatch = ''
      cp ${./package-lock.json} ./package-lock.json
      substituteInPlace ./rt/src/deserialize.mts \
        --replace 'process.env.TROUPE' '"${troupeCompiler}"'
    '';
    npmDepsHash = "sha256-ybSK40LF3zrKGosJH6rncW+DtuPUaQ8VKcfzccPYcew=";

    dontNpmBuild = true;

    buildPhase = ''
      ${typescript}/bin/tsc -p rt

      find ./lib -maxdepth 1 -type f -name '*.trp' -exec ${lib.getExe troupeCompiler} {} -l \;
      find ./trp-rt -maxdepth 1 -type f -name '*.trp' -exec ${lib.getExe troupeCompiler} {} -l \;
    '';

    postInstall = ''
      cp -r ./rt/built $out/lib/node_modules/picomlret/rt/built

      mkdir -p $out/bin
      cp ${runtimeWrapper} $out/bin/troupe
      substituteInPlace $out/bin/troupe \
        --subst-var-by 'troupe_rt' "$out/lib/node_modules/picomlret/rt/built/troupe.mjs" \
        --subst-var-by 'troupe' "$out"

      mkdir -p $out/lib
      cp -r ./lib/out $out/lib
      mkdir -p $out/trp-rt
      cp -r ./trp-rt/out $out/trp-rt

      ln -s ${troupeCompiler}/bin/troupec $out/bin/troupec
      ln -s $out/lib/node_modules/picomlret/rt $out/rt

      # Teacher's scripts assume files are .js instead of .mjs, so create symlinks for all of them
      find $out/rt/built -name "*.mjs" -exec bash -c 'ln -s $(realpath "{}") $(echo "{}" | sed "s/\.mjs$/\.js/" -)' \;
    '';
  };

  troupeCompiler = haskellPackages.mkDerivation {
    inherit version;
    pname = "troupec";

    src = "${src}/compiler";

    libraryHaskellDepends = with haskellPackages; [
      aeson
      alex
      base
      base64-bytestring
      cereal
      happy
      MissingH
      tasty-golden
    ];

    # tests are outside compiler directory, too much work to fix
    doCheck = false;

    postPatch = ''
      cp ${./Troupe-compiler.cabal} ./Troupe-compiler.cabal
    '';

    preBuild = ''
      export TROUPE=$src
    '';

    postInstall = ''
      mkdir -p $out/lib/out
      cp ${src}/lib/out/* $out/lib/out

      mkdir -p $out/trp-rt/out
      cp ${src}/trp-rt/out/* $out/trp-rt/out
    '';

    isExecutable = true;

    license = lib.licenses.unfree;
    mainProgram = "troupec";
  };
in
  troupeRuntime
