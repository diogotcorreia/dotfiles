{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  python3Packages,
}:
buildHomeAssistantComponent (finalAttrs: {
  owner = "Mincka";
  domain = "spotcast";
  version = "6.6.0";

  src = fetchFromGitHub {
    owner = "Mincka";
    repo = "spotcast";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NuFV0CIE7i19AVslcRnCaBm03Hc8qyvoP03VfaLR9BM=";
  };

  propagatedBuildInputs = with python3Packages; [
    spotipy
    spotifyaio
    rapidfuzz
  ];

  meta = {
    changelog = "https://github.com/fondberg/spotcast/releases";
    description = "Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices";
    homepage = "https://github.com/fondberg/spotcast";
    license = lib.licenses.asl20;
  };
})
