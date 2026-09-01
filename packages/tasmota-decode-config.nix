{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "tasmota-decode-config";
  version = "15.6.0";

  src = fetchFromGitHub {
    owner = "tasmota";
    repo = "decode-config";
    tag = "v${finalAttrs.version}";
    hash = "sha256-4axn3T4fSAe9Z0I3L58vjYOla2OggIp7PqS+oC0ZmtE=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    configargparse
    paho-mqtt
    requests
  ];

  pyproject = true;

  postInstall = ''
    mv $out/bin/decode-config{.py,}
  '';

  meta = with lib; {
    description = "Backup/restore and decode configuration tool for Tasmota";
    homepage = "https://github.com/tasmota/decode-config";
    license = licenses.lgpl3;
    mainProgram = "decode-config";
    platforms = platforms.linux;
  };
})
