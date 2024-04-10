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
  version = "unstable-2023-06-17";

  src = fetchFromGitHub {
    owner = "TroupeLang";
    repo = "Troupe";
    rev = "a979eeaa62ea9a9ce35128ef64a118197a5c03b2";
    hash = "sha256-f/3Zcswrcc7/PPr7w3SLPukDZ2CuQEbe46M4DbEq4uY=";
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
      substituteInPlace ./rt/src/deserialize.ts \
        --replace 'process.env.TROUPE' '"${troupeCompiler}"'
    '';
    npmDepsHash = "sha256-w5pHbGdnItqgjBKq8lg96CXmmDdB8N3SaUswtcQjhug=";

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
        --subst-var-by 'troupe_rt' "$out/lib/node_modules/picomlret/rt/built/troupe.js" \
        --subst-var-by 'troupe' "$out"

      mkdir -p $out/lib
      cp -r ./lib/out $out/lib
      mkdir -p $out/trp-rt
      cp -r ./trp-rt/out $out/trp-rt

      ln -s ${troupeCompiler}/bin/troupec $out/bin/troupec
      ln -s $out/lib/node_modules/picomlret/rt $out/rt
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
