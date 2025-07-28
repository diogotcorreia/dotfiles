{
  fetchPypi,
  lib,
  python3Packages,
  cmake,
  libiberty,
  elfutils,
  libdwarf,
  ...
}:
python3Packages.buildPythonPackage rec {
  pname = "libdebug";
  version = "0.8.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-9InvU/JSIFoAwAkYwKtMVU138Wo7qZmHec7fqCU5LL4=";
  };

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail "/usr/include/libiberty" "${lib.getDev libiberty}/include/libiberty" \
      --replace-fail "/usr/include/libdwarf-0" "${lib.getDev libdwarf}/include/libdwarf-0"
  '';

  # ensure only scikit-build-core runs CMakeLists.txt
  dontConfigure = true;

  build-system = with python3Packages; [
    scikit-build-core
    cmake
    ninja
  ];

  propagatedBuildInputs =
    with python3Packages;
    [
      nanobind
      typing-extensions
      psutil
      requests
      prompt-toolkit
    ]
    ++ [
      libiberty
      elfutils
      libdwarf
    ];

  format = "pyproject"; # no setup.py

  meta = with lib; {
    description = "Programmatic debugging of userland binary executables";
    homepage = "https://libdebug.org/";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
