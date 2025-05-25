{
  fetchFromGitHub,
  lib,
  libnetfilter_queue,
  libnfnetlink,
  python3Packages,
  ...
}:
python3Packages.buildPythonPackage rec {
  pname = "netfilterqueue";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "oremanj";
    repo = "python-netfilterqueue";
    tag = "v${version}";
    hash = "sha256-2/EF+WGy5SjunaMonQmN2TQ8G5awh1Cvn90LRx7QS9k=";
  };

  nativeBuildInputs = with python3Packages; [
    cython
  ];

  buildInputs = [
    libnetfilter_queue
    libnfnetlink
  ];

  meta = with lib; {
    description = "Python bindings for libnetfilter_queue";
    homepage = "https://github.com/oremanj/python-netfilterqueue";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
