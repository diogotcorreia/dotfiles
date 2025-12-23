{ lib, ... }:
{
  security.pam.services.swaylock = { };
  hm.programs.swaylock = {
    enable = true;
    # TODO: play around with settings
    settings = {
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      show-failed-attempts = true;
      ignore-empty-password = true;
    }
    // (with lib.my.colors; {
      # colors
      color = black;
      bs-hl-color = orange;
      key-hl-color = teal;
      caps-lock-bs-hl-color = orange;
      caps-lock-key-hl-color = teal;
      separator-color = black;
      layout-bg-color = "${black}c0";
      layout-text-color = lightwhite;

      inside-color = "${grey}c0";
      inside-clear-color = "${yellow}c0";
      inside-caps-lock-color = "${black}c0";
      inside-ver-color = "${lightblue}c0";
      inside-wrong-color = "${red}c0";

      line-color = black;
      line-clear-color = black;
      line-caps-lock-color = black;
      line-ver-color = black;
      line-wrong-color = black;

      ring-color = green;
      ring-clear-color = yellow;
      ring-caps-lock-color = yellow;
      ring-ver-color = darkblue;
      ring-wrong-color = pink;

      text-color = orange;
      text-clear-color = black;
      text-caps-lock-color = orange;
      text-ver-color = black;
      text-wrong-color = black;
    });
  };
}
