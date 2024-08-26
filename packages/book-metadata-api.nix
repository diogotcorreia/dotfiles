{
  fetchFromGitHub,
  makeWrapper,
  mkYarnPackage,
  nodejs,
  chromium,
  fetchYarnDeps,
  pkg-config,
  vips,
  nodePackages,
  python3,
  ...
}: let
  pin = {
    version = "3.1.1";
    srcHash = "sha256-cbMH8u7vVNsbQFmOtzTbll6ZfF3eqJtxiaLV9A2BFhA=";
    yarnSha256 = "sha256-jlwg/QLIMuA45C36oQQ6BA7Yhp3y8LGktZyFH0d1F40=";
  };
in
  mkYarnPackage rec {
    pname = "book-metadata-api";
    inherit (pin) version;

    src = fetchFromGitHub {
      owner = "livraria-papelaria-espaco";
      repo = "book-metadata-api";
      rev = "v${version}";
      hash = pin.srcHash;
    };

    # packageJSON = ./package.json;

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      sha256 = pin.yarnSha256;
    };

    doDist = false;

    yarnPreBuild = ''
      mkdir -p $HOME/.node-gyp/${nodejs.version}
      echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
      ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
      export npm_config_nodedir=${nodejs}
    '';

    pkgConfig = {
      sharp = {
        nativeBuildInputs = [
          pkg-config
          nodePackages.semver
          nodePackages.node-gyp
          # nodePackages.node-gyp-build
          # nodePackages.node-pre-gyp
          python3
        ];
        buildInputs = [vips];
        postInstall = ''
          yarn --offline run install
        '';
      };
    };

    nativeBuildInputs = [nodejs makeWrapper chromium];

    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    postInstall = ''
      makeWrapper '${nodejs}/bin/node' "$out/bin/book-metadata-api" \
        --add-flags "$out/libexec/book-metadata-api/deps/book-metadata-api/src/index.js" \
        --set PUPPETEER_SKIP_DOWNLOAD 1 \
        --set PUPPETEER_EXECUTABLE_PATH ${chromium}/bin/chromium
    '';
  }
