# GnuPG (GPG) agent configuration
{pkgs, ...}: {
  hm.programs.gpg.enable = true;
  hm.services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };
}
