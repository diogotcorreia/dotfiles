{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication rec {
  pname = "pyinstxtractor";
  version = "2024.04";

  src = fetchFromGitHub {
    owner = "extremecoders-re";
    repo = "pyinstxtractor";
    rev = "refs/tags/${version}";
    hash = "sha256-Wx/q67mkbAEfraSL/37PICa4zLn5O/2oCiLzwMLU4M8=";
  };

  format = "other"; # no setup.py

  # Add shebang
  patchPhase = ''
    sed -i '1 i\#!/usr/bin/env python3' pyinstxtractor.py
  '';

  installPhase = ''
    install -Dm0775 pyinstxtractor.py $out/bin/pyinstxtractor
  '';

  meta = with lib; {
    description = "Python script to extract the contents of a PyInstaller generated executable file";
    homepage = "https://github.com/extremecoders-re/pyinstxtractor";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
