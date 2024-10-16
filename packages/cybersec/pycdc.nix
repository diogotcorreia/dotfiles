{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "pycdc";
  version = "unstable-2024-03-12";

  src = fetchFromGitHub {
    owner = "zrax";
    repo = "pycdc";
    rev = "6467c2cc52aa714876e131a1b6c6cf25f129460f";
    hash = "sha256-V3vl/waOPf7H3mXd2LdWPMbbhfyDmddrp2HiYIud5qo=";
  };

  nativeBuildInputs = [cmake];

  meta = with lib; {
    description = "C++ python bytecode disassembler and decompiler";
    homepage = "https://github.com/zrax/pycdc";
    license = licenses.gpl3;
    mainProgram = "pycdc";
    platforms = platforms.linux;
  };
}
