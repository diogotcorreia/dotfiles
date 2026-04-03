{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  python3Packages,
}:
let
  trafiklab-sl = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "trafiklab-sl";
    version = "2.2.0";

    src = fetchFromGitHub {
      owner = "NecroKote";
      repo = "trafiklab-sl";
      tag = "v${finalAttrs.version}";
      hash = "sha256-l57q/CBdGQ0jf5wSoMg3mjOxl2YtaY6hyHSWGnmAEQY=";
    };
    pyproject = true;

    build-system = with python3Packages; [ setuptools ];

    dependencies = with python3Packages; [
      aiohttp
    ];

    meta = with lib; {
      description = "Storstockholms Lokaltrafik (SL) data via Trafiklab API";
      homepage = "https://github.com/NecroKote/trafiklab-sl";
      license = licenses.mit;
    };
  });
in
buildHomeAssistantComponent rec {
  owner = "hasl-sensor";
  domain = "hasl3";
  version = "0-unstable-2026-03-29";

  src = fetchFromGitHub {
    owner = "hasl-sensor";
    repo = "integration";
    rev = "18a2d26918e999b4747a4796461d3bd600f33be1";
    hash = "sha256-WMJ1NaeMlvHQIUST8jJtHPZNBHGqku2LKZbj/kyDT+k=";
  };

  propagatedBuildInputs = with python3Packages; [
    isodate
    trafiklab-sl
  ];

  meta = with lib; {
    changelog = "https://github.com/hasl-sensor/integration/blob/${src.rev}/CHANGELOG.md";
    description = "Swedish Public Transport Sensor (HASL)";
    homepage = "https://github.com/hasl-sensor/integration";
    license = licenses.asl20;
  };
}
