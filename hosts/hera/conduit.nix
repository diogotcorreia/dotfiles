# Configuration for Conduit (Matrix Homeserver) on Hera
{
  config,
  lib,
  pkgs,
  ...
}: let
  domainConduit = "m.diogotc.com";
  portConduit = lib.my.ports.conduit;
  domainElement = "chat.diogotc.com";

  # https://web-docs.element.dev/Element%20Web/config.html
  elementConfig = {
    default_server_name = "diogotc.com";
    disable_custom_urls = true;
    disable_guests = true;
    disable_login_language_selector = false;
    disable_3pid = true;
    brand = "DTC Element";

    integrations_ui_url = "https://scalar.vector.im/";
    integrations_rest_url = "https://scalar.vector.im/api";
    integrations_widgets_urls = [
      "https://scalar.vector.im/_matrix/integrations/v1"
      "https://scalar.vector.im/api"
      "https://scalar-staging.vector.im/_matrix/integrations/v1"
      "https://scalar-staging.vector.im/api"
      "https://scalar-staging.riot.im/scalar/api"
    ];
    integrations_jitsi_widget_url = "https://scalar.vector.im/api/widgets/jitsi.html";

    default_country_code = "PT";

    show_labs_settings = true;
    features = {};
    default_federate = true;
    default_theme = "dark";
    room_directory = {
      servers = ["diogotc.com"];
    };
    setting_defaults = {
      breadcrumbs = true;
    };
    jitsi = {
      preferred_domain = "meet.element.io";
    };
    element_call = {
      url = "https://call.element.io";
      participant_limit = 8;
      brand = "Element Call";
    };
    map_style_url = "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx";
  };
in {
  # TODO move docker containers to NixOS services

  services.caddy.virtualHosts = {
    ${domainConduit} = {
      enableACME = true;
      extraConfig = ''
        header /.well-known/matrix/* Content-Type application/json
        header /.well-known/matrix/* Access-Control-Allow-Origin *
        respond /.well-known/matrix/server `{"m.server": "m.diogotc.com:443"}`
        respond /.well-known/matrix/client `{"m.homeserver": {"base_url": "https://m.diogotc.com"}, "org.matrix.msc3575.proxy": {"url": "https://m.diogotc.com"}}`
        reverse_proxy /_matrix/* localhost:${toString portConduit} {
          import CLOUDFLARE_PROXY
        }
        reverse_proxy /_synapse/client/* localhost:${toString portConduit} {
          import CLOUDFLARE_PROXY
        }
      '';
    };
    ${domainElement} = let
      elementPkg = pkgs.element-web.override {
        conf = elementConfig;
      };
    in {
      enableACME = true;
      extraConfig = ''
        root ${elementPkg}
        file_server
      '';
    };
  };

  modules.services.restic.paths = ["${config.my.homeDirectory}/conduit"];
}
