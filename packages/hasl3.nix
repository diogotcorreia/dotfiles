{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  home-assistant,
}:
buildHomeAssistantComponent rec {
  owner = "hasl-sensor";
  domain = "hasl3";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "hasl-sensor";
    repo = "integration";
    rev = version;
    hash = "sha256-NhOf1pVeZ+Er5ZF4QUm3aueJeftmcSVPe66aiTwTD9g=";
  };

  propagatedBuildInputs = with home-assistant.python.pkgs; [
    httpx
    jsonpickle
    isodate
  ];

  meta = with lib; {
    changelog = "https://github.com/hasl-sensor/integration/blob/${version}/CHANGELOG.md";
    description = "Swedish Public Transport Sensor (HASL)";
    homepage = "https://github.com/hasl-sensor/integration";
    license = licenses.asl20;
  };
}
