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
      patchCliBinScript =
        let
          script = pkgs.fetchurl {
            url = "https://pastebin.com/raw/JDJVjsxG";
            hash = "sha256-TpqMfe8lxPcwySqWverFIoTAf35KojzmainHnNm+2eI=";
          };
        in
        pkgs.runCommand "patch-caido-cli" { } ''
          cat ${script} | tr -d '\r' > ./script
          install -m 555 ./script $out
          patchShebangs $out
        '';

      # Replace cloud-server signing key with our own
      # Our key: 8a88e3dd7409f195fd52db2d3cba5d72ca6709bf1d94121bf3748801b40f6f5c
      newKey = ''\x8a\x88\xe3\xdd\x74\x09\xf1\x95\xfd\x52\xdb\x2d\x3c\xba\x5d\x72\xca\x67\x09\xbf\x1d\x94\x12\x1b\xf3\x74\x88\x01\xb4\x0f\x6f\x5c'';
      patchedCaidoCli = pkgs.caido-cli.overrideAttrs (prev: {
        postPatch = prev.postPatch or "" + ''
          ${patchCliBinScript} "./caido-cli" '${newKey}'
        '';
      });

      # It's not easy to patch an app image, so we are basically copying the derivation and editing it in-place
      caidoDesktop = pkgs.caido-desktop;
      appImageContents = pkgs.appimageTools.extractType2 {
        inherit (caidoDesktop) pname version src;
        postExtract = ''
          ${patchCliBinScript} "$out/resources/bin/caido-cli" '${newKey}'
        '';
      };
      patchedCaidoDesktop = pkgs.appimageTools.wrapAppImage {
        inherit (caidoDesktop) pname version meta;
        src = appImageContents;

        nativeBuildInputs = [ pkgs.makeWrapper ];
        extraPkgs = pkgs: [ pkgs.libthai ];

        extraInstallCommands = ''
          install -m 444 -D ${appImageContents}/caido.desktop \
            -t $out/share/applications
          substituteInPlace $out/share/applications/caido.desktop \
            --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=caido-desktop %U"
          install -m 444 -D ${appImageContents}/caido.png \
            $out/share/icons/hicolor/512x512/apps/caido.png
          wrapProgram $out/bin/${caidoDesktop.pname} \
            --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

        '';
      };
    in
    [
      patchedCaidoCli
      patchedCaidoDesktop
    ];

  # Make certificate and private key available to our user
  age.secrets.caidoCaPrivateKey = {
    file = secrets.caidoCaPrivateKey;
    owner = user;
  };
  hm.xdg.configFile."caido-offline/certificate.crt".source = ./certificate.crt;
}
