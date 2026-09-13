# Builds from release zip instead of source so that we can build dev builds instead.
{
  lib,
  fetchurl,
  jre,
  makeWrapper,
  stdenv,
  unzip,
  versionCheckHook,
  writeShellScriptBin,
  writeText,
  zip,
  ...
}:
let

  config = writeText "arlington.xml" /* xml */ ''
    <AutomatedInstallation langpack="eng">
        <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
        <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
            <installpath>/tmp/build</installpath>
        </com.izforge.izpack.panels.target.TargetPanel>
        <com.izforge.izpack.panels.packs.PacksPanel id="sdk_pack_select">
            <pack index="0" name="veraPDF GUI" selected="true"/>
            <pack index="1" name="veraPDF Mac and *nix Scripts" selected="true"/>
            <pack index="2" name="veraPDF Validation model" selected="true"/>
            <pack index="3" name="veraPDF Documentation" selected="true"/>
            <pack index="4" name="veraPDF Sample Plugins" selected="false"/>
        </com.izforge.izpack.panels.packs.PacksPanel>
        <com.izforge.izpack.panels.install.InstallPanel id="install"/>
        <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
    </AutomatedInstallation>
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "arlington-verapdf";
  version = "1.31.174";
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://software.verapdf.org/dev/arlington/${lib.versions.majorMinor finalAttrs.version}/verapdf-arlington-${finalAttrs.version}-installer.zip";
    hash = "sha256-uZIeVCCf6yXDqlQCcpDru6d5svaYB+QSozXDitotxuE=";
  };

  # izpack tries to use /bin/chmod, which doe snot exist in nix, we need to patch it with a binary of the same length
  # https://github.com/izpack/izpack/blob/430005582cc06f097939a412b099542bcbc62fdc/izpack-util/src/main/java/com/izforge/izpack/util/FileExecutor.java#L335
  postPatch = ''
    jar=verapdf-izpack-installer-${finalAttrs.version}.jar
    class="com/izforge/izpack/util/FileExecutor.class"
    unzip "$jar" "$class"
    sed -i 's|/bin/chmod|aaaaachmod|g' "$class"
    zip -u "$jar" "$class"
  '';

  nativeBuildInputs = [
    zip
    unzip
    jre
    makeWrapper
    (writeShellScriptBin "aaaaachmod" ''
      chmod "$@"
    '')
  ];

  buildPhase = ''
    runHook preBuild

    ./verapdf-install ${config}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp -r /tmp/build "$out/share"

    makeWrapper ${lib.getExe jre} $out/bin/arlington-verapdf-gui --add-flags "-jar $out/share/bin/gui-arlington-${finalAttrs.version}.jar"
    makeWrapper ${lib.getExe jre} $out/bin/arlington-verapdf --add-flags "-jar $out/share/bin/cli-arlington-${finalAttrs.version}.jar"

    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  versionCheckProgram = "${placeholder "out"}/bin/arlington-verapdf";

  meta = {
    changelog = "https://github.com/veraPDF/veraPDF-library/blob/${finalAttrs.src.tag}/RELEASENOTES.md";
    description = "Command line and GUI industry supported PDF/A and PDF/UA Validation";
    homepage = "https://github.com/veraPDF/veraPDF-apps/tree/arlington";
    license = lib.licenses.OR [
      lib.licenses.gpl3Plus
      lib.licenses.mpl20
    ];
  };
})
