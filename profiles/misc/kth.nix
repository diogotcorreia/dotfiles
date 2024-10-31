# Configuration for services and programs needed while studying
# at Royal Institute of Technology (KTH).
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) escapeShellArg getAttr attrNames;

  courseUrls = {
    cybsam = "https://canvas.kth.se/courses/41786";
    cybsam2 = "https://canvas.kth.se/courses/49203";
    devops = "https://canvas.kth.se/courses/48942";
    tamos = "https://canvas.kth.se/courses/49054";
    tamos-discussion = "https://canvas.kth.se/courses/32837";
    forensics = "https://canvas.kth.se/courses/50595";
    cybtamos = "https://canvas.kth.se/courses/50613";
  };
in {
  # Course shortcuts
  hm.home.packages = map (courseName:
    pkgs.writeScriptBin courseName ''
      ${pkgs.xdg-utils}/bin/xdg-open ${
        escapeShellArg (getAttr courseName courseUrls)
      }
    '') (attrNames courseUrls);

  hm.programs.git.includes = [
    {
      condition = "gitdir:~/documents/kth/";
      contents.user = {
        name = "Diogo Correia";
        email = "diogotc@kth.se";
      };
    }
  ];
}
