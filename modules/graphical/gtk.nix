# GTK theme configuration
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.graphical.gtk;
in {
  options.modules.graphical.gtk.enable = mkEnableOption "gtk";

  config = mkIf cfg.enable {
    # https://nix-community.github.io/home-manager/index.html#_why_do_i_get_an_error_message_about_literal_ca_desrt_dconf_literal_or_literal_dconf_service_literal
    programs.dconf.enable = true;

    hm.gtk = {
      enable = true;

      theme = {
        package = pkgs.nordic;
        name = "Nordic-darker";
      };

      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };
    };
  };
}
