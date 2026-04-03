# Discord bot to provide alternative URLS to various social media sites
{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "alt-urls-discord-bot";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "alt-urls-discord-bot";
    tag = "v${version}";
    hash = "sha256-bqpbAlo9vR0IxKFnRLMliurbPT0aAdZ+2UYWdYt7ZD4=";
  };

  cargoHash = "sha256-gKp1sp9uLpMt9AiZcmY3kk1l3D2p1NXLrJgJk8T73h0=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
