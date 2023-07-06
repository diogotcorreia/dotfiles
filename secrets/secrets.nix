let
  bacchusSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuipxCcMp+IAh5TegpQxFqxsUHPHys1QxPwLoky7nCd";
  phobosSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";
in {
  "nebulaCA.age".publicKeys = [ bacchusSystem phobosSystem ];
  "openvpnIstAuthUserPass.age".publicKeys = [ bacchusSystem ];

  "bacchus/nebulaCert.age".publicKeys = [ bacchusSystem ];
  "bacchus/nebulaKey.age".publicKeys = [ bacchusSystem ];
  "bacchus/cscptWireguardPrivateKey.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticHealthchecksUrl.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticRcloneConfig.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticPassword.age".publicKeys = [ bacchusSystem ];
  "bacchus/resticSshKey.age".publicKeys = [ bacchusSystem ];

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
