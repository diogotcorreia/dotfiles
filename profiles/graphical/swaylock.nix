{ ... }:
{
  security.pam.services.swaylock = { };
  hm.programs.swaylock = {
    enable = true;
    # TODO: play around with settings
    settings = {
      color = "808080";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "ffffff";
      show-failed-attempts = true;
    };
  };
}
