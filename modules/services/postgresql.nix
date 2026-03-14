# Postgresql configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  resticCfg = config.modules.services.restic;
  postgresqlCfg = config.services.postgresql;

  psql = lib.getExe' postgresqlCfg.package "psql";
  ownershipClauses = lib.concatMap (
    user:
    map (
      db: ''${psql} -tAc 'ALTER DATABASE "${db}" OWNER TO "${user.name}";' ''
    ) user.ensureDBOwnershipOf
  ) postgresqlCfg.ensureUsers;
in
{
  options.services.postgresql = {
    ensureUsers = mkOption {
      type = types.listOf (
        types.submodule ({
          options = {
            ensureDBOwnershipOf = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Grants the user ownership to the given databases.
                This databases must be defined manually in
                [](#opt-services.postgresql.ensureDatabases).
              '';
            };
          };
        })
      );
    };
  };

  config = mkIf postgresqlCfg.enable {
    # Tweak PostgreSQL performance for SSDs
    # https://pgtune.leopard.in.ua/?dbVersion=18&osType=linux&dbType=web&cpuNum=&totalMemory=4&totalMemoryUnit=GB&connectionNum=&hdType=ssd
    services.postgresql.settings = {
      max_connections = 200;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
    };

    # Handle backup of PostgreSQL databases
    modules.services.restic = {
      stdinFromCommand = [
        {
          fileName = "postgresql_dumpall.sql";
          tags = [ "postgresql" ];
          command = [
            (lib.getExe' postgresqlCfg.package "pg_dumpall")
            "--no-role-passwords"
          ];
        }
      ];
    };

    # Setup restic user on postgresql
    services.postgresql.ensureUsers = mkIf resticCfg.enable [
      {
        name = "restic";
      }
    ];
    systemd.services.postgresql-setup.serviceConfig.ExecStartPost =
      lib.optionals resticCfg.enable [
        "${psql} -c 'GRANT pg_read_all_data TO restic;'"
      ]
      ++ ownershipClauses;

    # Persist databases when using tmpfs
    modules.impermanence.directories = [ "/var/lib/postgresql" ];
  };
}
