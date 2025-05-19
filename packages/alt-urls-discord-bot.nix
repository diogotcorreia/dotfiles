# Discord bot to provide alternative URLS to various social media sites
{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "alt-urls-discord-bot";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "alt-urls-discord-bot";
    rev = "v${version}";
    hash = "sha256-+SX4mLW8Dl0m5PPsWRETHziqgvNDvKzbOHEskK2ja7w=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-lQtwm6G/hcsw3xgpvJMC00OFaTCX26PE9if+FqbLfuE=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
