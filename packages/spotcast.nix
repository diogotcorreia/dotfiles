{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  home-assistant,
}:
buildHomeAssistantComponent rec {
  owner = "fondberg";
  domain = "spotcast";
  version = "6.0.0-a16";

  src = fetchFromGitHub {
    owner = "fondberg";
    repo = "spotcast";
    rev = "v${version}";
    hash = "sha256-4E9wyfh3OnP2zkdeWLabwVdMitqECInz7nH5Te8t5B8=";
  };

  propagatedBuildInputs = with home-assistant.python.pkgs; [
    spotipy
    spotifyaio
    rapidfuzz
  ];

  meta = with lib; {
    changelog = "https://github.com/fondberg/spotcast/releases";
    description = "Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices";
    homepage = "https://github.com/fondberg/spotcast";
    license = licenses.asl20;
  };
}
