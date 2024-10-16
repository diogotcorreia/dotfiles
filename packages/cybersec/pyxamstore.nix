# https://www.thecobraden.com/posts/unpacking_xamarin_assembly_stores/
{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "pyxamstore";
  version = "unstable-2023-05-14";

  src = fetchFromGitHub {
    owner = "jakev";
    repo = "pyxamstore";
    rev = "23cd52612702d08495570f96f60883d6047ae429";
    hash = "sha256-A1eTzgu/KSWsXasXCGRLlXaqKp4/le8MsNY3NK/ocf0=";
  };

  # Check phase is failing with some pip error
  doCheck = false;

  nativeBuildInputs = with python3Packages; [
    setuptools
  ];

  propagatedBuildInputs = with python3Packages; [
    future
    lz4
    xxhash
  ];

  meta = with lib; {
    description = "Python utility for parsing Xamarin AssemblyStore blob files";
    homepage = "https://github.com/jakev/pyxamstore";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
