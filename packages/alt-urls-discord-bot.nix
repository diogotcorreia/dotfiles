# Discord bot to provide alternative URLS to various social media sites
{
  fetchFromGitHub,
  lib,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "alt-urls-discord-bot";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "alt-urls-discord-bot";
    rev = "v${version}";
    hash = "sha256-K97dSFT/i2f5cYTNYF8S4ax5d4zuIgVSDcH5o4o6AGc=";
  };

  cargoHash = "sha256-z1lvhLkA2DB5whntlCBU1+1CX62Qk5h5OAtqavlSHKE=";

  meta = with lib; {
    description = "Discord bot that provides alternative links to various social media services ";
    homepage = "https://github.com/diogotcorreia/alt-urls-discord-bot";
    license = licenses.gpl3;
    mainProgram = "alt-urls-discord-bot";
    platforms = platforms.all;
  };
}
