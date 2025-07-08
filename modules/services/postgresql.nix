# Postgresql configuration
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;

  resticCfg = config.modules.services.restic;
  postgresqlCfg = config.services.postgresql;
in {
  config = mkIf postgresqlCfg.enable {
    # Handle backup of PostgreSQL databases
    modules.services.restic = {
      stdinFromCommand = [
        {
          fileName = "postgresql_dumpall.sql";
          tags = ["postgresql"];
          command = [(lib.getExe' postgresqlCfg.package "pg_dumpall") "--no-role-passwords"];
        }
      ];
    };

    # Setup restic user on postgresql
    services.postgresql.ensureUsers = mkIf resticCfg.enable [
      {
        name = "restic";
      }
    ];
    systemd.services.postgresql.serviceConfig.ExecStartPost =
      mkIf resticCfg.enable
      [
        ''
          ${lib.getExe' postgresqlCfg.package "psql"} -c "GRANT pg_read_all_data TO restic;"
        ''
      ];

    # Persist databases when using tmpfs
    modules.impermanence.directories = ["/var/lib/postgresql"];
  };
}
