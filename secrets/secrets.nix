let
  phobosSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";
in {
  "nebulaCA.age".publicKeys = [ phobosSystem ];

  "phobos/healthchecksUrl.age".publicKeys = [ phobosSystem ];
  "phobos/nebulaCert.age".publicKeys = [ phobosSystem ];
  "phobos/nebulaKey.age".publicKeys = [ phobosSystem ];
  "phobos/resticHealthchecksUrl.age".publicKeys = [ phobosSystem ];
  "phobos/resticRcloneConfig.age".publicKeys = [ phobosSystem ];
  "phobos/resticPassword.age".publicKeys = [ phobosSystem ];
  "phobos/resticSshKey.age".publicKeys = [ phobosSystem ];
}
