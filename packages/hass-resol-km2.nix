{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  ...
}:
buildHomeAssistantComponent rec {
  owner = "evercape";
  domain = "resol";
  version = "2024.11.0";

  src = fetchFromGitHub {
    owner = "evercape";
    repo = "hass-resol-KM2";
    tag = version;
    hash = "sha256-fyObGaIIusXztiBNBsIuyPrkERTpAIWJGmx5MSNfQWI=";
  };

  meta = with lib; {
    description = "Log sensor information from Resol devices using KM2 communication module";
    homepage = "https://github.com/evercape/hass-resol-KM2";
    license = licenses.mit;
  };
}
