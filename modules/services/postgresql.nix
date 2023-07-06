# modules/services/postgresql.nix
#
# Author: Diogo Correia <me@diogotc.com>
# URL:    https://github.com/diogotcorreia/dotfiles
#
# Postgresql configuration

{ pkgs, config, lib, ... }:
let
  inherit (builtins) concatStringsSep;
  inherit (lib) mkIf escapeShellArg;

  postgresqlCfg = config.services.postgresql;

  postgresqlUser = "postgres";
  compressSuffix = ".zstd";
  compressCmd = "${pkgs.zstd}/bin/zstd -c --adapt";

  getFilePath = databaseName:
    "/tmp/postgresql_db_${databaseName}.sql${compressSuffix}";

  getPrepareCommand = databaseName: ''
    ${pkgs.coreutils}/bin/install -b -m 600 /dev/null ${
      getFilePath databaseName
    }
    ${pkgs.sudo}/bin/sudo -u ${postgresqlUser} ${pkgs.postgresql}/bin/pg_dump --format=custom ${
      escapeShellArg databaseName
    } | ${compressCmd} > ${getFilePath databaseName}
  '';
  getCleanupCommand = databaseName:
    "${pkgs.coreutils}/bin/rm ${getFilePath databaseName}";
in {

  # Handle backup of PostgreSQL databases
  config = mkIf postgresqlCfg.enable {
    modules.services.restic = {
      paths = map getFilePath postgresqlCfg.ensureDatabases;
      backupPrepareCommand = concatStringsSep "\n"
        (map getPrepareCommand postgresqlCfg.ensureDatabases);
      backupCleanupCommand = concatStringsSep "\n"
        (map getCleanupCommand postgresqlCfg.ensureDatabases);
    };
  };
}
