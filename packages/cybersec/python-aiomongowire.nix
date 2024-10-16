{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonPackage {
  pname = "aiomongowire";
  version = "unstable-2021-08-15";

  src = fetchFromGitHub {
    owner = "upcFrost";
    repo = "aiomongowire";
    rev = "408e56c0398ee4041642506fefd2e373885d2790";
    hash = "sha256-8OQ880C6F4xFaFV6HFyW2F2S7+9UPnQDEtSZk6NOz3A=";
  };

  propagatedBuildInputs = with python3Packages; [
    bson
    python-snappy
    zstandard
  ];

  nativeCheckInputs = with python3Packages; [
    pytest
  ];

  meta = with lib; {
    description = "Mongo Wire Protocol for asyncio (Python module)";
    homepage = "https://github.com/upcFrost/aiomongowire";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
