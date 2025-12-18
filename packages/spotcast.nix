{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  home-assistant,
}:
buildHomeAssistantComponent rec {
  owner = "fondberg";
  domain = "spotcast";
  version = "6.0.0-a15";

  src = fetchFromGitHub {
    owner = "fondberg";
    repo = "spotcast";
    rev = "v${version}";
    hash = "sha256-ROlyRPxhQS5pznj3vSHyfOQ2EE/8XOri0J65EC2ePTg=";
  };

  propagatedBuildInputs = with home-assistant.python.pkgs; [
    spotipy
    spotifyaio
    rapidfuzz
  ];

  # https://github.com/joostlek/python-spotify/issues/718
  ignoreVersionRequirement = [ "spotifyaio" ];

  meta = with lib; {
    changelog = "https://github.com/fondberg/spotcast/releases";
    description = "Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices";
    homepage = "https://github.com/fondberg/spotcast";
    license = licenses.asl20;
  };
}
