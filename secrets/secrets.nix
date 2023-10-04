let
  bacchusSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuipxCcMp+IAh5TegpQxFqxsUHPHys1QxPwLoky7nCd";
  heraSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/L7HpMOr7L8qDBJRF19lXR90xrn7tHmjhMnQhGGqvO";
  phobosSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";
in {
  "nebulaCA.age".publicKeys = [ bacchusSystem heraSystem phobosSystem ];
  "openvpnIstAuthUserPass.age".publicKeys = [ bacchusSystem ];
  "openvpnKthEN2720Config.age".publicKeys = [ bacchusSystem ];

  "bacchus/nebulaCert.age".publicKeys = [ bacchusSystem ];
  "bacchus/nebulaKey.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticHealthchecksUrl.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticRcloneConfig.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticPassword.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticSshKey.age".publicKeys = [ bacchusSystem ];

  "hera/acmeDnsCredentials.age".publicKeys = [ heraSystem ];
  "hera/diskstationSambaCredentials.age".publicKeys = [ heraSystem ];
  "hera/fireflyAutoDataImporterEnv.age".publicKeys = [ heraSystem ];
  "hera/fireflyAutoDataImporterHealthchecksUrl.age".publicKeys = [ heraSystem ];
  "hera/fireflyDataImporterEnv.age".publicKeys = [ heraSystem ];
  "hera/healthchecksUrl.age".publicKeys = [ heraSystem ];
  "hera/istDelegateElectionFenixSecret.age".publicKeys = [ heraSystem ];
  "hera/nebulaCert.age".publicKeys = [ heraSystem ];
  "hera/nebulaKey.age".publicKeys = [ heraSystem ];
  "hera/paperlessEnvVariables.age".publicKeys = [ heraSystem ];
  "hera/resticHealthchecksUrl.age".publicKeys = [ heraSystem ];
  "hera/resticRcloneConfig.age".publicKeys = [ heraSystem ];
  "hera/resticPassword.age".publicKeys = [ heraSystem ];
  "hera/resticSshKey.age".publicKeys = [ heraSystem ];

  "phobos/healthchecksEnvVariables.age".publicKeys = [ phobosSystem ];
  "phobos/healthchecksSecretKey.age".publicKeys = [ phobosSystem ];
  "phobos/healthchecksUrl.age".publicKeys = [ phobosSystem ];
  "phobos/nebulaCert.age".publicKeys = [ phobosSystem ];
  "phobos/nebulaKey.age".publicKeys = [ phobosSystem ];
  "phobos/resticHealthchecksUrl.age".publicKeys = [ phobosSystem ];
  "phobos/resticRcloneConfig.age".publicKeys = [ phobosSystem ];
  "phobos/resticPassword.age".publicKeys = [ phobosSystem ];
  "phobos/resticSshKey.age".publicKeys = [ phobosSystem ];
}
