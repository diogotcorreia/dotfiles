let
  apolloSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBotkuo1Z6ZbLFhfx7qt7lUS8Kr3xnu1X1fqjlbQ8BLE";
  bacchusSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuipxCcMp+IAh5TegpQxFqxsUHPHys1QxPwLoky7nCd";
  broSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4GODzTdoSU1RS/1RU+EDZN1TxDYxqRct2q+OeWgv0f";
  febSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVtyO4NZ3FNrffEJOGLzkVgtgpkMV1ouRkk34GslroU";
  heraSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/L7HpMOr7L8qDBJRF19lXR90xrn7tHmjhMnQhGGqvO";
  phobosSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";

  personalSystems = [apolloSystem bacchusSystem];
  serverSystems = [broSystem febSystem heraSystem phobosSystem];
  allSystems = personalSystems ++ serverSystems;

  mkSystem = dir: publicKeys: files:
    builtins.foldl' (acc: file: let
      filePrefix =
        if dir == null
        then ""
        else "${dir}/";
    in
      acc
      ++ [
        {
          name = "${filePrefix}${file}.age";
          value = {inherit publicKeys;};
        }
      ]) []
    files;

  flatten = list: builtins.foldl' (acc: system: acc ++ system) [] list;
  mkSecrets = systems: builtins.listToAttrs (flatten systems);
in
  mkSecrets [
    (mkSystem null allSystems [
      "ecscWireguardPrivateKey"
      "nebulaCA"
      "nixCacheDiogotcReadTokenNetrc"
    ])

    (mkSystem "apollo" [apolloSystem] [
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
    ])

    (mkSystem "bacchus" [bacchusSystem] [
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
      "wireguardClientHeraPrivateKey"
    ])

    (mkSystem "bro" [broSystem] [
      "acmeDnsCredentials"
      "autoUpgradeHealthchecksUrl"
      "cloudflareToken"
      "hassSecrets"
      "healthchecksUrl"
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
    ])

    (mkSystem "feb" [febSystem] [
      "autoUpgradeHealthchecksUrl"
      "cloudflareToken"
      "hassSecrets"
      "healthchecksUrl"
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
    ])

    (mkSystem "hera" [heraSystem] [
      "acmeDnsCredentials"
      "autoUpgradeHealthchecksUrl"
      "diskstationSambaCredentials"
      "fireflyAutoDataImporterEnv"
      "fireflyAutoDataImporterHealthchecksUrl"
      "fireflyDataImporterEnv"
      "healthchecksUrl"
      "istDelegateElectionFenixSecret"
      "nebulaCert"
      "nebulaKey"
      "nextcloudSecrets"
      "paperlessEnvVariables"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
      "transmissionProxySshConfig"
      "transmissionProxySshPassword"
      "wireguardPrivateKey"
    ])

    (mkSystem "phobos" [phobosSystem] [
      "atticdEnvVariables"
      "autoUpgradeHealthchecksUrl"
      "healthchecksEnvVariables"
      "healthchecksSecretKey"
      "healthchecksUrl"
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
    ])
  ]
