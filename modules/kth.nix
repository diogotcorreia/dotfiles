# modules/kth.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Configuration for services and programs needed while studying
# at Royal Institute of Technology (KTH).

{ pkgs, config, lib, secretsDir, ... }:
let
  inherit (lib) mkEnableOption mkIf escapeShellArg getAttr attrNames;
  cfg = config.modules.kth;

  courseUrls = {
    nss = "https://canvas.kth.se/courses/42913";
    cybsoc = "https://canvas.kth.se/courses/43064";
    cybsam = "https://canvas.kth.se/courses/41786";
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

    # IL1333
    environment.systemPackages = with pkgs; [
      (quartus-prime-lite.override { supportedDevices = [ "Cyclone V" ]; })
      cutecom
    ];
    services.udev.packages = [ pkgs.usb-blaster-udev-rules ];
  };
}
