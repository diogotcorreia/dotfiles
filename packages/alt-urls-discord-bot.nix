# Discord bot to provide alternative URLS to various social media sites
{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "alt-urls-discord-bot";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "alt-urls-discord-bot";
    rev = "v${version}";
    hash = "sha256-4TCELsFRY5EuewQq+jGKAFput7GpXhZQkwCIs/WO0oY=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-MvvYUHfwTcwzY2Qpc3wU/RcA15uavZ1vDS6k1KxqcPc=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
