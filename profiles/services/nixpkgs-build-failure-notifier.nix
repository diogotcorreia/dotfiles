# Setup nixpkgs-build-failure-notifier server
{
  config,
  inputs,
  lib,
  secrets,
  ...
}:
{
  imports = [
    inputs.nixpkgs-build-failure-notifier.nixosModules.nixpkgs-build-failure-notifier
  ];

  age.secrets = {
    nixpkgsBuildFailureNotifierEnv.file = secrets.host.nixpkgsBuildFailureNotifierEnv;
    nixpkgsBuildFailureNotifierHealthchecksUrl = {
      file = secrets.host.nixpkgsBuildFailureNotifierHealthchecksUrl;
      owner = config.services.nixpkgs-build-failure-notifier.user;
    };
  };

  services.nixpkgs-build-failure-notifier = {
    enable = true;
    configureDatabase = true;

    jobsets = [
      "nixpkgs:unstable"
      "nixpkgs:staging-next"
      "nixpkgs:staging-next-25.11"
      "nixos:release-25.11:nixpkgs."
    ];

    maintainers = [
      "diogotcorreia"
    ];

    environment = {
      SMTP_HOST = "mail.diogotc.com";
      SMTP_USERNAME = lib.my.mkRobotsEmail "nixpkgs-build-failure-notifier";
      SMTP_FROM = "Nixpkgs Build Failure Notifier <${lib.my.mkRobotsEmail "nixpkgs-build-failure-notifier"}>";
      SMTP_TO = lib.my.mkDtcEmail "nixpkgs-build-failure-notifier";
    };
    # contains SMTP_PASSWORD
    environmentFile = config.age.secrets.nixpkgsBuildFailureNotifierEnv.path;

    timerExpression = "05:24";
  };

  modules.services.healthchecks.systemd-monitoring = {
    nixpkgs-build-failure-notifier.checkUrlFile =
      config.age.secrets.nixpkgsBuildFailureNotifierHealthchecksUrl.path;
  };
}
