# Lightweight Maven repository
# https://reposilite.com
{
  fetchurl,
  jdk_headless,
  lib,
  makeWrapper,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "reposilite-bin";
  version = "3.5.14";

  jar = fetchurl {
    url = "https://maven.reposilite.com/releases/com/reposilite/reposilite/${version}/reposilite-${version}-all.jar";
    hash = "sha256-qZXYpz6SBXDBj8c0IZkfVgxEFe/+DxMpdhLJsjks8cM=";
  };

  dontUnpack = true;

  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    runHook preInstall
    makeWrapper ${lib.getExe jdk_headless} $out/bin/reposilite \
      --add-flags "-Xmx40m -jar $jar" \
      --set JAVA_HOME ${jdk_headless}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight and easy-to-use repository management software dedicated for the Maven based artifacts in the JVM ecosystem";
    homepage = "https://github.com/dzikoysk/reposilite";
    license = licenses.asl20;
    mainProgram = "reposilite";
    platforms = platforms.linux;
  };
}
