# Copied from open PR https://github.com/NixOS/nixpkgs/pull/295211
# TODO: remove when merged upstream
{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "json2kdl";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "AgathaSorceress";
    repo = "json2kdl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-+Tp8fNGMFD/hI7begMpNbERVVxRMgCX/fIc6eUOToUg=";
  };

  cargoHash = "sha256-bDEoUpQgJWjQryi9UY5pAjMfK3+pVwPs/ZfqlEjE8gE=";

  meta = {
    description = "Program that converts JSON files to KDL";
    homepage = "https://github.com/AgathaSorceress/json2kdl";
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ feathecutie ];
  };
})
