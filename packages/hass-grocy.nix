{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  python3Packages,
}:
let
  grocy-py = python3Packages.buildPythonPackage (finalAttrs: {
    pname = "grocy-py";
    version = "1.5.1";

    src = fetchFromGitHub {
      owner = "iamkarlson";
      repo = "grocy-py";
      tag = finalAttrs.version;
      hash = "sha256-VUBpX7vfTzBI1QzNqN90jRGxJqNcASxcmz0cCe+H0dk=";
    };
    pyproject = true;

    build-system = with python3Packages; [
      setuptools
      setuptools-scm
    ];

    dependencies = with python3Packages; [
      requests
      pydantic
      tzdata
      tzlocal
    ];

    meta = {
      changelog = "https://github.com/iamkarlson/grocy-py/releases/tag/${finalAttrs.src.tag}";
      description = "Python client library for Grocy ERP API";
      homepage = "https://github.com/iamkarlson/grocy-py";
      license = lib.licenses.mit;
    };
  });
in
buildHomeAssistantComponent (finalAttrs: {
  owner = "iamkarlson";
  domain = "grocy";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "iamkarlson";
    repo = "grocy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gcDGb1PDBunlhhHGG4MIhhggz4Gr/hXYutChwbXsLXo=";
  };

  propagatedBuildInputs = with python3Packages; [
    icalendar
    grocy-py
  ];

  meta = {
    changelog = "https://github.com/iamkarlson/grocy/releases/tag/${finalAttrs.src.tag}";
    description = "Custom Grocy integration for Home Assistant";
    homepage = "https://github.com/iamkarlson/grocy";
    license = lib.licenses.asl20;
  };
})
