{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication rec {
  pname = "jwt-tool";
  version = "2.2.6";

  src = fetchFromGitHub {
    owner = "ticarpi";
    repo = "jwt_tool";
    rev = "refs/tags/v${version}";
    hash = "sha256-PqeEOn0F6xcHpgtkK+p6K8SoiGhjonnbAW0zzWq3laY=";
  };

  propagatedBuildInputs = with python3Packages; [
    # cprint
    pycryptodomex
    requests
    termcolor
  ];

  format = "other"; # no setup.py

  installPhase = ''
    install -Dm0775 jwt_tool.py $out/bin/jwt-tool
  '';

  meta = with lib; {
    description = "A toolkit for testing, tweaking and cracking JSON Web Tokens";
    homepage = "https://github.com/ticarpi/jwt_tool";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
