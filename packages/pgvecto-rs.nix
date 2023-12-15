# packages/pgvecto-rs.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# A PostgreSQL extension needed for Immich.
# This builds from the pre-compiled binary instead of from source.

{ lib, stdenv, fetchurl, dpkg, postgresql }:

let
  versionHashes = {
    "14" = "sha256-8YRC1Cd9i0BGUJwLmUoPVshdD4nN66VV3p48ziy3ZbA=";
  };
  major = lib.versions.major postgresql.version;
in stdenv.mkDerivation rec {
  pname = "pgvecto-rs";
  version = "0.1.11";

  buildInputs = [ dpkg ];

  src = fetchurl {
    url =
      "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}-v${version}-x86_64-unknown-linux-gnu.deb";
    hash = versionHashes."${major}";
  };

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
    install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
    rm -rf $out/usr
  '';

  meta = with lib; {
    description =
      "pgvecto.rs extension for PostgreSQL: Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
    homepage = "https://github.com/tensorchord/pgvecto.rs";
  };
}
