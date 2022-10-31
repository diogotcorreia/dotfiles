let
  phobosSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";
in { "phobosHealthchecksUrl.age".publicKeys = [ phobosSystem ]; }
