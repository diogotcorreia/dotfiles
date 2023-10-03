{ stdenv, lib, autoPatchelfHook, fetchurl, makeDesktopItem, makeWrapper
, alsa-lib, at-spi2-core, cairo, cups, curl, dbus, dpkg, expat, ffmpeg
, fontconfig, freetype, gdk-pixbuf, glib, glibc, gtk3, libappindicator-gtk3
, libdrm, libnotify, libopus, libpulseaudio, libsecret, libX11, libXScrnSaver
, libXcomposite, libXcursor, libXdamage, libXext, libXfixes, libXi, libxkbcommon
, libXrandr, libXrender, libXtst, libxcb, mesa, nspr, nss, pango, udev, x264
, xdg-utils }:

let
  libPath = lib.makeLibraryPath [
    curl
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    ffmpeg
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libnotify
    nss
    nspr
    udev
    libdrm
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libxkbcommon
    libXrandr
    # libXScrnSaver
    # libXtst
    xdg-utils
    #libutil #libglibutil
    libappindicator-gtk3
    libsecret
    libpulseaudio
    libopus
    mesa
    pango
  ];
in stdenv.mkDerivation rec {
  inherit libPath;
  pname = "airtame";
  version = "4.6.3";
  longName = "${pname}-application";

  src = fetchurl {
    url =
      "https://downloads.airtame.com/app/latest/linux/Airtame-${version}.deb";
    sha256 = "sha256-vU04EtfYk6iK9g9v+QmxaD1naRKllPbGNqOydds4HPo=";
  };

  nativeBuildInputs = [ dpkg makeWrapper autoPatchelfHook ];

  buildInputs = [
    curl
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    ffmpeg
    glib
    gtk3
    libnotify
    nss
    nspr
    libdrm
    libX11
    libxcb
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libxkbcommon
    libXrandr
    # libXScrnSaver
    # libXtst
    xdg-utils
    #libutil #libglibutil
    libappindicator-gtk3
    libsecret
    libpulseaudio
    libopus
    mesa
    pango
  ];

  # desktopItem = makeDesktopItem rec {
  # # TODO
  # name = "airtame";
  # exec = longName;
  # comment = "Airtame Streaming Client";
  # desktopName = "Airtame";
  # icon = name;
  # genericName = comment;
  # categories = "Network;";
  # };

  unpackPhase = ''
    runHook preUnpack

    dpkg -x $src ./src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    opt="$out/opt/${longName}"
    mkdir -p "$opt"
    cp -R ./src/opt/Airtame/* "$opt"
    mkdir -p "$out/bin"
    ln -s "$opt/${longName}" "$out/bin/"
    #mkdir -p "$out/share"
    #cp -r "{desktopItem}/share/applications" "$out/share/"
    #mkdir -p "$out/share/icons"
    #ln -s "$opt/icon.png" "$out/share/icons/airtame.png"

    # Fix /build/ not allowed in rpath
    # mv "$opt/resources/build" "$opt/resources/build-out"

    # Flags and rpath are copied from launch-airtame.sh.
    vendorlib="\
    $opt/resources/build-out/native/out/lib:\
    $opt/resources/build-out/native/out/lib/airtame-modules"

    echo $vendorlib

    # rpath="${libPath}:$opt:$vendorlib"

    # find "$opt" \( -type f -executable -o -name "*.so" -o -name "*.so.*" \) \
      # -exec patchelf --set-rpath "$rpath" {} \;

    # The main binary also needs libudev which was removed by --shrink-rpath.
    # interp="$(< $NIX_CC/nix-support/dynamic-linker)"
    # patchelf --set-interpreter "$interp" $opt/${longName}
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
        $opt/${longName}

    wrapProgramShell $opt/${longName} \
      --prefix LD_LIBRARY_PATH : ${libPath}:$opt:$vendorlib \
      --add-flags "--disable-gpu --enable-transparent-visuals"

    runHook postInstall
  '';

  # dontPatchELF = true;

  meta = with lib; {
    homepage = "https://airtame.com/download";
    description = "Wireless streaming client for Airtame devices";
    license = licenses.unfree;
    maintainers = with maintainers; [ thanegill ];
    platforms = platforms.linux;
  };
}
