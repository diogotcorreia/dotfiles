# GnuPG (GPG) agent configuration
{pkgs, ...}: {
  hm.programs.gpg.enable = true;
  hm.services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gtk2;
  };
}
