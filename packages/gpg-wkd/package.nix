# Generate a directory that can be served as a WKD server
# Inspiration from: https://www.postsubmeta.net/blog/2021/02/15/static-openpgp-web-key-directory-setup/
{
  sequoia-sq,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "gpg-wkd";
  version = "1.0.0";

  src = ./diogo.gpg.asc;
  dontUnpack = true;

  nativeBuildInputs = [ sequoia-sq ];
  installPhase = ''
    mkdir $out
    export SEQUOIA_CERT_STORE="$(mktemp -d)"
    sq network wkd publish --create --method advanced --cert-file "$src" --domain diogotc.com "$out"
    rm -rf "$SEQUOIA_CERT_STORE"
    cp "$src" "$out/diogo.gpg.asc"
  '';
}
