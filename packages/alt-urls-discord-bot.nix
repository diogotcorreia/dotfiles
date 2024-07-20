# Discord bot to provide alternative URLS to various social media sites
{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "alt-urls-discord-bot";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "alt-urls-discord-bot";
    rev = "v${version}";
    hash = "sha256-vMX1pZ7VUuY3qpoXqpJtOtSoJ/MvjacEcSPDCMdZJ0s=";
  };

  cargoHash = "sha256-HWLW8Bab65L8bKw4vHYwuYJ0R0y3QhLRl8jyX1H3VAs=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
