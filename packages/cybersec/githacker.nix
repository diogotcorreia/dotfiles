{
  fetchFromGitHub,
  lib,
  python3Packages,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "githacker";
  version = "unstable-2024-03-26";

  src = fetchFromGitHub {
    owner = "WangYihang";
    repo = "GitHacker";
    rev = "4a5362d632f8bcc082224303a171c0bad3c6a6d1";
    hash = "sha256-YPF9bs2N3otHKUWWvbDqbkWIZB3xbKTvpga8yr95n/g=";
  };

  propagatedBuildInputs = with python3Packages; [
    beautifulsoup4
    coloredlogs
    gitpython
    requests
    semver
  ];

  meta = with lib; {
    description = "A .git folder exploiting tool that is able to restore the entire Git repository";
    homepage = "https://github.com/WangYihang/GitHacker";
    license = licenses.free; # repo does not have a license
    platforms = platforms.linux;
  };
}
