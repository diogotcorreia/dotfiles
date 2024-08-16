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

  cargoHash = "sha256-YpIPZby8vIKoTG3ZeREw8iO2tbGtt9+hGKdi7vrIIRY=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
