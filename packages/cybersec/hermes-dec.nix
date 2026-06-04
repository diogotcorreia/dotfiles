{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "hermes-dec";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "P1sec";
    repo = "hermes-dec";
    tag = finalAttrs.version;
    hash = "sha256-aQLO19k7XXDJjW6hCGTILws8HSU1IpJTTr+SBXx5dK4=";
  };

  postPatch = ''
    substituteInPlace ./pyproject.toml \
      --replace-fail '"uv_build>=0.10.3,<0.11.0"' '"uv_build"'
  '';

  build-system = with python3Packages; [
    uv-build
  ];

  dependencies = with python3Packages; [
    uv-build
  ];

  pyproject = true;

  meta = with lib; {
    description = "A reverse engineering tool for decompiling and disassembling the React Native Hermes bytecode";
    homepage = "https://github.com/P1sec/hermes-dec";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
  };
})
