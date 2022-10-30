let
  phobosSystem =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0BA0ZOaTwVfVSpaK9zSc8KFOz4oW0ZWbn5CgxX8uy/";
in { "phobosHealthchecksUrl.age".publicKeys = [ phobosSystem ]; }
