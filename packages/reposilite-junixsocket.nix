# Wrap reposilite to add junixsocket-common to classpath
{
  fetchurl,
  reposilite,
  runCommand,
  stdenvNoCC,
  ...
}:
let
  junixsocket = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "junixsocket";
    version = "2.10.1";

    src = fetchurl {
      url = "https://github.com/kohlschutter/junixsocket/releases/download/junixsocket-${finalAttrs.version}/junixsocket-dist-${finalAttrs.version}-bin.tar.gz";
      hash = "sha256-EQ0gO2d487Y1cZJ9Z+0QsBlagdpYU8CTANxmmOobGbA=";
    };

    installPhase = ''
      mkdir -p "$out/lib"
      cp "./lib/junixsocket-common-${finalAttrs.version}.jar" "$out/lib/junixsocket-common.jar"
      cp "./lib/junixsocket-native-common-${finalAttrs.version}.jar" "$out/lib/junixsocket-native-common.jar"
    '';
  });
in
runCommand "reposilite-junixsocket"
  {
    meta.mainProgram = "reposilite";
  }
  ''
    mkdir -p "$out/bin"
    cp "${reposilite}/bin/reposilite" "$out/bin/reposilite"
    substituteInPlace "$out/bin/reposilite" \
      --replace-fail "-jar ${reposilite}/lib/reposilite" "-cp ${reposilite}/lib/reposilite:${junixsocket}/lib/junixsocket-common.jar:${junixsocket}/lib/junixsocket-native-common.jar com.reposilite.ReposiliteLauncherKt"
  ''
