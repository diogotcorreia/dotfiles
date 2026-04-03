{
  fetchPypi,
  lib,
  python3Packages,
  cmake,
  elfutils,
  libdwarf,
  libiberty,
  pkg-config,
  zlib,
  zstd,
  ...
}:
python3Packages.buildPythonPackage rec {
  pname = "libdebug";
  version = "0.9.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-rk2Cq7YpN/z530LAFzWKm1I33j24rsSKbQV7Ezv5E34=";
  };

  # ensure only scikit-build-core runs CMakeLists.txt
  dontConfigure = true;

  build-system =
    with python3Packages;
    [
      cmake
      nanobind
      ninja
      scikit-build-core
      typing-extensions
    ]
    ++ [
      pkg-config
    ];

  dependencies = with python3Packages; [
    prompt-toolkit
    psutil
    pyelftools
    requests
  ];

  propagatedBuildInputs = [
    libiberty
    elfutils
    libdwarf
    zlib
    zstd
  ];

  format = "pyproject"; # no setup.py

  meta = with lib; {
    description = "Programmatic debugging of userland binary executables";
    homepage = "https://libdebug.org/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
