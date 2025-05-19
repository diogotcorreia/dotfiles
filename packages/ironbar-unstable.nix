# Use nightly version of ironbar because it supports niri workspaces
# TODO: remove on NixOS 25.11 (hopefully they will have made a release by then)
{
  gtk3,
  gdk-pixbuf,
  librsvg,
  webp-pixbuf-loader,
  gobject-introspection,
  glib-networking,
  glib,
  shared-mime-info,
  gsettings-desktop-schemas,
  wrapGAppsHook3,
  gtk-layer-shell,
  adwaita-icon-theme,
  libxkbcommon,
  libdbusmenu-gtk3,
  openssl,
  pkg-config,
  hicolor-icon-theme,
  lib,
  fetchFromGitHub,
  luajit,
  luajitPackages,
  libpulseaudio,
  libudev-zero,
  libevdev,
  libinput,
  unstable,
  features ? [],
  ...
}: let
  hasFeature = f: features == [] || builtins.elem f features;
in
  unstable.rustPlatform.buildRustPackage rec {
    pname = "ironbar";
    version = "0-unstable-2025-03-27";

    src = fetchFromGitHub {
      owner = "JakeStanger";
      repo = "ironbar";
      rev = "41d29d84c865d2fe714b8a69b0913a00799d4e98";
      hash = "sha256-vhigccpbFEkqQmdDfkllVeRvq3NXoLL8WzrpPrKuAwQ=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-wpaFjjleWVOtpz63ZQxea7CVNBQ/EjCQx+qnvg6qUdA=";

    buildInputs =
      [
        gtk3
        gdk-pixbuf
        glib
        gtk-layer-shell
        glib-networking
        shared-mime-info
        adwaita-icon-theme
        hicolor-icon-theme
        gsettings-desktop-schemas
        libxkbcommon
      ]
      ++ lib.optionals (hasFeature "http") [openssl]
      ++ lib.optionals (hasFeature "volume") [libpulseaudio]
      ++ lib.optionals (hasFeature "cairo") [luajit]
      ++ lib.optionals (hasFeature "tray") [libdbusmenu-gtk3]
      ++ lib.optionals (hasFeature "keyboard") [libevdev libinput];

    nativeBuildInputs = [
      pkg-config
      wrapGAppsHook3
      gobject-introspection
    ];
    propagatedBuildInputs = [gtk3];

    runtimeDeps = [luajitPackages.lgi];

    buildNoDefaultFeatures = features != [];
    buildFeatures = features;

    gappsWrapperArgs =
      ''
        # Thumbnailers
        --prefix XDG_DATA_DIRS : "${gdk-pixbuf}/share"
        --prefix XDG_DATA_DIRS : "${librsvg}/share"
        --prefix XDG_DATA_DIRS : "${webp-pixbuf-loader}/share"
        --prefix XDG_DATA_DIRS : "${shared-mime-info}/share"

        # gtk-launch
        --suffix PATH : "${lib.makeBinPath [gtk3]}"
      ''
      + lib.optionalString (hasFeature "cairo") ''
        --prefix LUA_PATH : "./?.lua;${luajitPackages.lgi}/share/lua/5.1/?.lua;${luajitPackages.lgi}/share/lua/5.1/?/init.lua;${luajit}/share/lua/5.1/\?.lua;${luajit}/share/lua/5.1/?/init.lua"
        --prefix LUA_CPATH : "./?.so;${luajitPackages.lgi}/lib/lua/5.1/?.so;${luajit}/lib/lua/5.1/?.so;${luajit}/lib/lua/5.1/loadall.so"
      '';

    preFixup = ''
      gappsWrapperArgs+=(
        ${gappsWrapperArgs}
      )
    '';

    meta = with lib; {
      homepage = "https://github.com/JakeStanger/ironbar";
      description = "Customizable gtk-layer-shell wlroots/sway bar written in Rust";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [
        yavko
        donovanglover
        jakestanger
      ];
      mainProgram = "ironbar";
    };
  }
