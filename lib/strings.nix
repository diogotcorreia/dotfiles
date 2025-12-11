{ lib, ... }:
{
  # Mainly for avoiding scraping of email addresses
  mkDtcEmail = user: "${user}@diogotc.com";
  mkRobotsEmail = user: "${user}@robots.diogotc.com";

  mkTui = cmd: "alacritty -e ${lib.escapeShellArg cmd}";
}
