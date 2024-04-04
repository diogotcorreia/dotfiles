# Postgresql configuration
{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (builtins) concatStringsSep;
  inherit (lib) mkIf escapeShellArg;

  postgresqlCfg = config.services.postgresql;

  postgresqlUser = "postgres";
  compressSuffix = ".zstd";
  compressCmd = "${pkgs.zstd}/bin/zstd -c --adapt";

  getFilePath = databaseName: "/tmp/postgresql_db_${databaseName}.sql${compressSuffix}";

  getPrepareCommand = databaseName: ''
    ${pkgs.coreutils}/bin/install -b -m 600 /dev/null ${
      getFilePath databaseName
    }
    ${pkgs.sudo}/bin/sudo -u ${postgresqlUser} ${postgresqlCfg.package}/bin/pg_dump --format=custom ${
      escapeShellArg databaseName
    } | ${compressCmd} > ${getFilePath databaseName}
  '';
  getCleanupCommand = databaseName: "${pkgs.coreutils}/bin/rm ${getFilePath databaseName}";
in {
  config = mkIf postgresqlCfg.enable {
    # Handle backup of PostgreSQL databases
    modules.services.restic = {
      paths = map getFilePath postgresqlCfg.ensureDatabases;
      backupPrepareCommand =
        concatStringsSep "\n"
        (map getPrepareCommand postgresqlCfg.ensureDatabases);
      backupCleanupCommand =
        concatStringsSep "\n"
        (map getCleanupCommand postgresqlCfg.ensureDatabases);
    };

    # Persist databases when using tmpfs
    modules.impermanence.directories = ["/var/lib/postgresql"];
  };
}
