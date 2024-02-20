# modules/kth.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for services and programs needed while studying
# at Royal Institute of Technology (KTH).
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf escapeShellArg getAttr attrNames;
  cfg = config.modules.kth;

  courseUrls = {
    acrypto = "https://canvas.kth.se/courses/45246";
    bnss = "https://canvas.kth.se/courses/44880";
    cybsam = "https://canvas.kth.se/courses/41786";
    hwsec = "https://canvas.kth.se/courses/45192";
  };
in {
  options.modules.kth.enable = mkEnableOption "kth";

  config = mkIf cfg.enable {
    # Course shortcuts
    hm.home.packages = map (courseName:
      pkgs.writeScriptBin courseName ''
        ${pkgs.xdg-utils}/bin/xdg-open ${
          escapeShellArg (getAttr courseName courseUrls)
        }
      '') (attrNames courseUrls);
  };
}
