{
  config,
  inputs,
  lib,
  ...
}: let
  cfgPersist = config.modules.impermanence;
  systemRoot = lib.optionalString cfgPersist.enable cfgPersist.persistDirectory;
in {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = ["${systemRoot}/etc/ssh/ssh_host_ed25519_key"];
}
