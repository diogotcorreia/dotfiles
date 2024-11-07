let
  apolloSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBotkuo1Z6ZbLFhfx7qt7lUS8Kr3xnu1X1fqjlbQ8BLE";
  athenaSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJT+5r75Hg9eTdKGav4SCYUkMPA3gRrrnLMB+IO6sDlk";
  bacchusSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuipxCcMp+IAh5TegpQxFqxsUHPHys1QxPwLoky7nCd";
  broSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4GODzTdoSU1RS/1RU+EDZN1TxDYxqRct2q+OeWgv0f";
  febSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVtyO4NZ3FNrffEJOGLzkVgtgpkMV1ouRkk34GslroU";
  heraSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/L7HpMOr7L8qDBJRF19lXR90xrn7tHmjhMnQhGGqvO";
  phobosSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";

  personalSystems = [apolloSystem bacchusSystem];
  serverSystems = [athenaSystem broSystem febSystem heraSystem phobosSystem];
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
      "nebulaCA"
      "nixCacheDiogotcReadTokenNetrc"
    ])

    (mkSystem null personalSystems [
      "ecscJeopardyWireguardPrivateKey"
      "ecscAdWireguardPrivateKey"
      "heroisDoMarWireguardPrivateKey"
    ])

    (mkSystem "apollo" [apolloSystem] [
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
    ])

    (mkSystem "athena" [athenaSystem] [
      "autoUpgradeHealthchecksUrl"
      "cloudflareToken"
      "healthchecksUrl"
      "meilisearchEnv"
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
      "umamiEnv"
    ])

    (mkSystem "bacchus" [bacchusSystem] [
      "nebulaCert"
      "nebulaKey"
      "resticHealthchecksUrl"
      "resticRcloneConfig"
      "resticPassword"
      "resticSshKey"
      "wireguardClientPrivateKey"
    ])

    (mkSystem "bro" [broSystem] [
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
      "altUrlsDiscordBotEnv"
      "autoUpgradeHealthchecksUrl"
      "cloudflareToken"
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
      "cloudflareToken"
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
