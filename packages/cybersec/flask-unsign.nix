{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication rec {
  pname = "flask-unsign";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "Paradoxis";
    repo = "Flask-Unsign";
    tag = "v${version}";
    hash = "sha256-6V5R/wTjxYX894Ep/8G2Vz/v8ZpXlCLpxKuhGCs+Xa0=";
  };

  pyproject = true;

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    flask
    requests
  ];

  meta = with lib; {
    description = "Command line tool to fetch, decode, brute-force and craft session cookies of a Flask application by guessing secret keys";
    homepage = "https://github.com/Paradoxis/Flask-Unsign";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
