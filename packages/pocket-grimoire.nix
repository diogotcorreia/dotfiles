{
  fetchFromGitHub,
  fetchYarnDeps,
  lib,
  nodejs,
  php84,
  yarnConfigHook,

  cacheDir ? "/var/cache/pocket-grimoire",
  logDir ? "/var/log/pocket-grimoire",
}:
let
  php = php84;

  # Pocket Grimoire uses the official icons as of https://github.com/Skateside/pocket-grimoire/commit/ae7f766be22863872274177aa7469d4944da3554
  # However, they are not included in the repo and must instead be downloaded
  # from the official botc-release repository.
  botcRelease = fetchFromGitHub {
    owner = "ThePandemoniumInstitute";
    repo = "botc-release";
    tag = "v3.53.3";
    hash = "sha256-kQlS+OejXXxzQNusdnG/LbHfnhIsNrUX65TwHGQyy1E=";
  };
in
php.buildComposerProject2 (finalAttrs: {
  pname = "pocket-grimoire";
  version = "2026.05.07";

  src = fetchFromGitHub {
    owner = "diogotcorreia";
    repo = "pocket-grimoire";
    tag = finalAttrs.version;
    hash = "sha256-A4UP0LQ93Tly8KwoPOGg5C2mCf6azeKhSMsiBLJj2W4=";
  };

  composerStrictValidation = false;
  composerNoPlugins = false;
  vendorHash = "sha256-DeUakUv1y2rvg8kIqQ2MJGEn9uxA+SC7YmpUMhnM9kA=";

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-usQJqesiX4SUWt+EaPSZHmqwpwm8/tK8f623T7cLgSw=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    nodejs
  ];

  postPatch = ''
    substituteInPlace config/packages/framework.yaml \
      --replace-fail '%env(APP_SECRET)%' '%env(file:APP_SECRET_FILE)%'
  '';

  preBuild = ''
    mkdir -p assets/img/roles
    find ${botcRelease}/resources/characters -name '*.webp' -exec cp {} assets/img/roles \;
    yarn --offline build
  '';

  postInstall = ''
    shopt -s dotglob
    chmod -R u+w $out/share
    mv $out/share/php/pocket-grimoire/* $out/
    rm -R $out/share $out/node_modules

    # remove unneeded files
    rm -rf $out/*.md $out/assets/{fonts,img,js,scss} $out/docker-compose.* $out/*.lock $out/package.json $out/webpack.config.js

    mkdir -p $out/var
    ln -s ${cacheDir} $out/var/cache
    ln -s ${logDir} $out/var/log
  '';

  passthru = {
    phpPackage = php;
  };

  meta = {
    description = "A mobile version of the Blood on the Clocktower grimoire ";
    homepage = "https://github.com/Skateside/pocket-grimoire";
    license = lib.licenses.gpl3Only;
    maintainers = [
      lib.maintainers.diogotcorreia
    ];
  };

})
