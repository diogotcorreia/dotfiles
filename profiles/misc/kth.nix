# Configuration for services and programs needed while studying
# at Royal Institute of Technology (KTH).
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) escapeShellArg getAttr attrNames;

  courseUrls = {
    acrypto = "https://canvas.kth.se/courses/45246";
    bnss = "https://canvas.kth.se/courses/44880";
    cybsam = "https://canvas.kth.se/courses/41786";
    fcrypto = "https://canvas.kth.se/courses/46237";
    hwsec = "https://canvas.kth.se/courses/45192";
    langsec = "https://canvas.kth.se/courses/46200";
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
