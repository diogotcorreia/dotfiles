{
  stdenv,
  lib,
  fetchFromGitHub,
  qt5,
  pcsclite,
  gengetopt,
  help2man,
  openssl,
  pkg-config,
  autoreconfHook,
  openjpeg,
  xercesc,
  xml-security-c,
  curlMinimal,
  libzip,
  swig,
  jdk,
  cjson,
  libsForQt5,
  openpace ? import ./openpace.nix {inherit stdenv gengetopt fetchFromGitHub help2man openssl pkg-config autoreconfHook;},
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "autenticacao-gov-pt";
  version = "3.13.0";
  src = fetchFromGitHub {
    owner = "amagovpt";
    repo = "autenticacao.gov";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YRHeiJJUtlG7yHRuHHwdwvq1ZWFzU7kNhPghd6Ps8FA=";
  };

  sourceRoot = "${finalAttrs.src.name}/pteid-mw-pt/_src/eidmw";

  qmakeFlags = [
    "PCSC_INCLUDE_DIR='${lib.getDev pcsclite}/include/PCSC'"
    "INSTALL_ROOT=${placeholder "out"}"
  ];

  installFlags = ["INSTALL_ROOT=${placeholder "out"}"];

  postPatch = ''
    substituteInPlace _Builds/eidcommon.mak \
      --replace-fail 'PREFIX_DIR = /usr/local' 'PREFIX_DIR = $${PREFIX}'
    substituteInPlace _Builds/pteidversions.mak \
      --replace-fail 'INSTALL_DIR=/usr/local' "$out"

    patchShebangs eidlibJava_Wrapper/create_java_files.sh
    substituteInPlace eidlibJava_Wrapper/eidlibJava_Wrapper.pro \
      --replace-fail '/usr/lib/jvm/java-11-openjdk-amd64' '${jdk}'

    substituteInPlace eidguiV2/eidguiV2.pro \
      --replace-fail '/usr/include/poppler/qt5' '${lib.getDev libsForQt5.poppler}/include/poppler/qt5'
  '';

  preInstall = ''
    cat pteid-poppler/Makefile
  '';

  buildInputs = [
    qt5.qtbase
    pcsclite
    openpace
  ];
  nativeBuildInputs = [
    qt5.qmake
    qt5.qtquickcontrols2
    libsForQt5.poppler
    # qt5.qtquickcontrols
    qt5.wrapQtAppsHook
    openjpeg
    pkg-config
    xercesc
    xml-security-c
    curlMinimal
    libzip
    swig
    jdk
    cjson
  ];
})
