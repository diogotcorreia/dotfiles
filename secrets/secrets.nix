let
  apolloSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBotkuo1Z6ZbLFhfx7qt7lUS8Kr3xnu1X1fqjlbQ8BLE";
  bacchusSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuipxCcMp+IAh5TegpQxFqxsUHPHys1QxPwLoky7nCd";
  broSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ4GODzTdoSU1RS/1RU+EDZN1TxDYxqRct2q+OeWgv0f";
  febSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVtyO4NZ3FNrffEJOGLzkVgtgpkMV1ouRkk34GslroU";
  heraSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/L7HpMOr7L8qDBJRF19lXR90xrn7tHmjhMnQhGGqvO";
  phobosSystem = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMDvcqB4ljQ4EvoiL6WS+8BqhtoMv/quzqExd3juqRU";

  personalSystems = [apolloSystem bacchusSystem];
  allSystems = personalSystems ++ [broSystem febSystem heraSystem phobosSystem];
in {
  "nebulaCA.age".publicKeys = allSystems;
  "nixCacheDiogotcReadTokenNetrc.age".publicKeys = allSystems;

  "apollo/nebulaCert.age".publicKeys = [apolloSystem];
  "apollo/nebulaKey.age".publicKeys = [apolloSystem];
  "apollo/resticHealthchecksUrl.age".publicKeys = [apolloSystem];
  "apollo/resticRcloneConfig.age".publicKeys = [apolloSystem];
  "apollo/resticPassword.age".publicKeys = [apolloSystem];
  "apollo/resticSshKey.age".publicKeys = [apolloSystem];

  "bacchus/nebulaCert.age".publicKeys = [bacchusSystem];
  "bacchus/nebulaKey.age".publicKeys = [bacchusSystem];
  "bacchus/resticHealthchecksUrl.age".publicKeys = [bacchusSystem];
  "bacchus/resticRcloneConfig.age".publicKeys = [bacchusSystem];
  "bacchus/resticPassword.age".publicKeys = [bacchusSystem];
  "bacchus/resticSshKey.age".publicKeys = [bacchusSystem];
  "bacchus/wireguardClientHeraPrivateKey.age".publicKeys = [bacchusSystem];

  "bro/acmeDnsCredentials.age".publicKeys = [broSystem];
  "bro/autoUpgradeHealthchecksUrl.age".publicKeys = [broSystem];
  "bro/cfdyndnsToken.age".publicKeys = [broSystem];
  "bro/hassSecrets.age".publicKeys = [broSystem];
  "bro/healthchecksUrl.age".publicKeys = [broSystem];
  "bro/nebulaCert.age".publicKeys = [broSystem];
  "bro/nebulaKey.age".publicKeys = [broSystem];
  "bro/resticHealthchecksUrl.age".publicKeys = [broSystem];
  "bro/resticRcloneConfig.age".publicKeys = [broSystem];
  "bro/resticPassword.age".publicKeys = [broSystem];
  "bro/resticSshKey.age".publicKeys = [broSystem];

  "feb/autoUpgradeHealthchecksUrl.age".publicKeys = [febSystem];
  "feb/cloudflareToken.age".publicKeys = [febSystem];
  "feb/hassSecrets.age".publicKeys = [febSystem];
  "feb/healthchecksUrl.age".publicKeys = [febSystem];
  "feb/nebulaCert.age".publicKeys = [febSystem];
  "feb/nebulaKey.age".publicKeys = [febSystem];
  "feb/resticHealthchecksUrl.age".publicKeys = [febSystem];
  "feb/resticRcloneConfig.age".publicKeys = [febSystem];
  "feb/resticPassword.age".publicKeys = [febSystem];
  "feb/resticSshKey.age".publicKeys = [febSystem];

  "hera/acmeDnsCredentials.age".publicKeys = [heraSystem];
  "hera/autoUpgradeHealthchecksUrl.age".publicKeys = [heraSystem];
  "hera/diskstationSambaCredentials.age".publicKeys = [heraSystem];
  "hera/fireflyAutoDataImporterEnv.age".publicKeys = [heraSystem];
  "hera/fireflyAutoDataImporterHealthchecksUrl.age".publicKeys = [heraSystem];
  "hera/fireflyDataImporterEnv.age".publicKeys = [heraSystem];
  "hera/healthchecksUrl.age".publicKeys = [heraSystem];
  "hera/istDelegateElectionFenixSecret.age".publicKeys = [heraSystem];
  "hera/nebulaCert.age".publicKeys = [heraSystem];
  "hera/nebulaKey.age".publicKeys = [heraSystem];
  "hera/nextcloudSecrets.age".publicKeys = [heraSystem];
  "hera/paperlessEnvVariables.age".publicKeys = [heraSystem];
  "hera/resticHealthchecksUrl.age".publicKeys = [heraSystem];
  "hera/resticRcloneConfig.age".publicKeys = [heraSystem];
  "hera/resticPassword.age".publicKeys = [heraSystem];
  "hera/resticSshKey.age".publicKeys = [heraSystem];
  "hera/transmissionProxySshConfig.age".publicKeys = [heraSystem];
  "hera/transmissionProxySshPassword.age".publicKeys = [heraSystem];
  "hera/wireguardPrivateKey.age".publicKeys = [heraSystem];

  "phobos/atticdEnvVariables.age".publicKeys = [phobosSystem];
  "phobos/autoUpgradeHealthchecksUrl.age".publicKeys = [phobosSystem];
  "phobos/healthchecksEnvVariables.age".publicKeys = [phobosSystem];
  "phobos/healthchecksSecretKey.age".publicKeys = [phobosSystem];
  "phobos/healthchecksUrl.age".publicKeys = [phobosSystem];
  "phobos/nebulaCert.age".publicKeys = [phobosSystem];
  "phobos/nebulaKey.age".publicKeys = [phobosSystem];
  "phobos/resticHealthchecksUrl.age".publicKeys = [phobosSystem];
  "phobos/resticRcloneConfig.age".publicKeys = [phobosSystem];
  "phobos/resticPassword.age".publicKeys = [phobosSystem];
  "phobos/resticSshKey.age".publicKeys = [phobosSystem];
}
