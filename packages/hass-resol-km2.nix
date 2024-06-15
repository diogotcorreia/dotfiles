{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  ...
}:
buildHomeAssistantComponent rec {
  owner = "evercape";
  domain = "resol";
  version = "2024.04.1";

  src = fetchFromGitHub {
    owner = "evercape";
    repo = "hass-resol-KM2";
    rev = version;
    hash = "sha256-mieJXhjjsyh7qtS863wUJqKwsaaKszJLadxx5yDKZJw=";
  };

  meta = with lib; {
    description = "Log sensor information from Resol devices using KM2 communication module";
    homepage = "https://github.com/evercape/hass-resol-KM2";
    license = licenses.mit;
  };
}
