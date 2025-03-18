{
  autoreconfHook,
  fetchFromGitHub,
  gengetopt,
  help2man,
  openssl,
  pkg-config,
  stdenv,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openpace";
  version = "1.1.3";
  src = fetchFromGitHub {
    owner = "frankmorgner";
    repo = "openpace";
    tag = finalAttrs.version;
    hash = "sha256-KsgCTHvbqxNOcf9HWgXGxagpIjHEcQ5Kryjq71F8XRk=";
  };

  nativeBuildInputs = [
    autoreconfHook
    help2man
    gengetopt
    openssl
    pkg-config
  ];
})
