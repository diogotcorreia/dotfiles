# Caido, but without login
# Due to legal reasons, the local server implementation is private
{
  lib,
  pkgs,
  secrets,
  user,
  ...
}:
let
  ip = "2001:db8::dcdc:1";
in
{
  # Redirect all requests meant for api.caido.io to our local server
  networking.hosts = {
    ${ip} = [ "api.caido.io" ];
  };

  networking.interfaces.lo.ipv6.addresses = [
    {
      address = ip;
      prefixLength = 112;
    }
  ];

  networking.nat.enable = true;
  networking.nat.enableIPv6 = true;
  networking.nftables.tables."nixos-nat6".content = lib.mkAfter ''
    chain out {
      ip6 daddr ${ip} tcp dport 443 counter dnat to [${ip}]:8443
    }
  '';

  # We need to have a custom CA certificate so that HTTPS still works
  security.pki.certificateFiles = [
    ./certificate.crt
  ];

  hm.home.packages =
    let
      caidoCli = pkgs.caido.override { appVariants = [ "cli" ]; };
      caidoDesktop = pkgs.caido.override { appVariants = [ "desktop" ]; };

      # Replace cloud-server signing key with our own
      # Original key: bfca3e77d29750f42e1f82745cab8686688c768b8c0418d0716db9018edf0ad3
      # Our key: 8a88e3dd7409f195fd52db2d3cba5d72ca6709bf1d94121bf3748801b40f6f5c
      patchCliBin = ''
        offset=$(LC_ALL=C grep -obUaP '\xbf\xca\x3e\x77\xd2\x97\x50\xf4\x2e\x1f\x82\x74\x5c\xab\x86\x86\x68\x8c\x76\x8b\x8c\x04\x18\xd0\x71\x6d\xb9\x01\x8e\xdf' ./caido-cli | cut -d: -f1)

        printf '\x8a\x88\xe3\xdd\x74\x09\xf1\x95\xfd\x52\xdb\x2d\x3c\xba\x5d\x72\xca\x67\x09\xbf\x1d\x94\x12\x1b\xf3\x74\x88\x01\xb4\x0f\x6f\x5c' | \
          dd of=./caido-cli bs=1 seek="$offset" conv=notrunc
      '';

      patchedCaidoCli = caidoCli.overrideAttrs (_prev: {
        postPatch = patchCliBin;
      });

      # It's not easy to patch an app image, so we are basically copying the derivation and editing it in-place
      appImageContents = pkgs.appimageTools.extract {
        inherit (caidoDesktop) pname version src;
        postExtract = ''
          pushd $out/resources/bin
          ${patchCliBin}
          popd
        '';
      };
      patchedCaidoDesktop = pkgs.appimageTools.wrapAppImage {
        inherit (caidoDesktop) pname version;
        src = appImageContents;

        nativeBuildInputs = [ pkgs.makeWrapper ];

        extraPkgs = pkgs: [ pkgs.libthai ];

        extraInstallCommands = ''
          install -m 444 -D ${appImageContents}/caido.desktop -t $out/share/applications
          install -m 444 -D ${appImageContents}/caido.png \
            $out/share/icons/hicolor/512x512/apps/caido.png
          wrapProgram $out/bin/caido \
            --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
        '';
      };

      patchedCaido = pkgs.stdenv.mkDerivation {
        inherit (patchedCaidoCli) pname version meta;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/bin
          ln -s ${patchedCaidoDesktop}/bin/caido $out/bin/caido
          ln -s ${patchedCaidoCli}/bin/caido-cli $out/bin/caido-cli
        '';
      };
    in
    [ patchedCaido ];

  # Make certificate and private key available to our user
  age.secrets.caidoCaPrivateKey = {
    file = secrets.caidoCaPrivateKey;
    owner = user;
  };
  hm.xdg.configFile."caido-offline/certificate.crt".source = ./certificate.crt;
}
