{...}: {
  # Mainly for avoiding scraping of email addresses
  mkDtcEmail = user: "${user}@diogotc.com";
  mkRobotsEmail = user: "${user}@robots.diogotc.com";
}
