{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "gplaydl";
  version = "2.1.5";

  src = fetchFromGitHub {
    owner = "rehmatworks";
    repo = "gplaydl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-d1pguApAA7j2mBQ2yoNtmUVJPx6bjj7GRn/hmjOisqI=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    typer
    rich
    httpx
  ];

  pyproject = true;

  meta = with lib; {
    description = "Command Line Google Play APK downloader";
    homepage = "https://github.com/rehmatworks/gplaydl";
    license = licenses.mit;
    platforms = platforms.linux;
  };
})
