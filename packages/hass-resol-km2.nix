{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  ...
}:
buildHomeAssistantComponent (finalAttrs: {
  owner = "evercape";
  domain = "resol";
  version = "2024.11.0";

  src = fetchFromGitHub {
    owner = "evercape";
    repo = "hass-resol-KM2";
    tag = finalAttrs.version;
    hash = "sha256-fyObGaIIusXztiBNBsIuyPrkERTpAIWJGmx5MSNfQWI=";
  };

  meta = {
    description = "Log sensor information from Resol devices using KM2 communication module";
    homepage = "https://github.com/evercape/hass-resol-KM2";
    license = lib.licenses.mit;
  };
})
