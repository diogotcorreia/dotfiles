# URL shortner
{
  fetchFromGitHub,
  lib,
  makeWrapper,
  runCommand,
  rustPlatform,
  ...
}:
let
  version = "5.6.1";

  src = fetchFromGitHub {
    owner = "SinTan1729";
    repo = "chhoto-url";
    tag = version;
    hash = "sha256-tjziMGodfz2RCXH+LCnJpiVUjNSX6Z39nqfNYXIEPis=";
  };

  web = runCommand "chhoto-url-resources" { } ''
    cp -r '${src}/resources' $out
  '';
in
rustPlatform.buildRustPackage {
  pname = "chhoto-url";
  inherit version src;

  sourceRoot = "${src.name}/actix";

  useFetchCargoVendor = true;
  cargoHash = "sha256-xbBg9REMLHC60t/YIbPBp5AVLdASV3cQ4ESxTrmkXfw=";

  nativeBuildInputs = [ makeWrapper ];

  patchPhase = ''
    runHook prePatch

    substituteInPlace src/main.rs \
      --replace-fail '"./resources/"' 'std::env::var("CHHOTO_URL_RESOURCES_DIR").unwrap_or("./resources/".to_string())' \
      --replace-fail '0.0.0.0' '::1'
    substituteInPlace src/services.rs \
      --replace-fail '"./resources/static/404.html"' 'format!("{}/static/404.html", std::env::var("CHHOTO_URL_RESOURCES_DIR").unwrap_or("./resources/".to_string()))'

    runHook postPatch
  '';

  postInstall = ''
    wrapProgram $out/bin/chhoto-url \
      --set CHHOTO_URL_RESOURCES_DIR '${web}'
  '';

  passthru = {
    inherit web;
  };

  meta = with lib; {
    description = "A simple, blazingly fast, selfhosted URL shortener with no unnecessary features; written in Rust.";
    homepage = "https://github.com/SinTan1729/chhoto-url";
    license = licenses.mit;
    mainProgram = "chhoto-url";
    platforms = platforms.all;
  };
}
