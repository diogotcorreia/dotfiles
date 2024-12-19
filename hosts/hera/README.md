# Hera

## Deployment

This host can be deployed using [nixos-anywhere](https://github.com/numtide/nixos-anywhere),
since its partition configuration is declared in hardware.nix.

The `/etc/ssh/ssh_host_ed25519_key` file should be provided when creating this machine in
order to be able to decrypt the agenix secrets.

To achieve this, create a tmp folder with `mktemp -d`, and then add the following files, where `$TEMP` is the directory just created:

- `$TEMP/persist/etc/ssh/ssh_host_ed25519_key`
- `$TEMP/persist/etc/ssh/ssh_host_ed25519_key.pub`

Other files can also be sent to the server using this method (i.e. restoring from backup).

Finally, run the nixos-anywhere command:

```bash
nix run github:numtide/nixos-anywhere -- --extra-files $TEMP --flake github:diogotcorreia/dotfiles#hera root@hera
```

## Restore Databases

### Nextcloud

```bash
zstd -d postgresql_db_nextcloud.sql.zstd
chown nextcloud:nextcloud postgresql_db_nextcloud.sql
sudo -u nextcloud pg_restore -d nextcloud -c --if-exists -1 postgresql_db_nextcloud.sql
```

### Firefly-III

```bash
cat path/to/firefly_db.sql | _ dce -T fireflyiiidb sh -c 'exec mysql --host=fireflyiiidb --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE'
```

To access the MySQL CLI, run

```bash
_ dce fireflyiiidb sh -c 'exec mysql --host=fireflyiiidb --user=$MYSQL_USER --password=$MYSQL_PASSWORD $MYSQL_DATABASE'
```

### Paperless

```bash
zstd -d postgresql_db_paperless.sql.zstd
chown paperless:paperless postgresql_db_paperless.sql
# might need to drop database and recreate it manually
sudo -u paperless pg_restore -d paperless -c --if-exists -1 postgresql_db_paperless.sql
```

### Immich

```bash
zstd -d postgresql_db_immich.sql.zstd
# user has to be postgres in order for vectors extension to be created properly
chown postgres:postgres postgresql_db_immich.sql
sudo -u postgres pg_restore -d immich -c --if-exists -1 postgresql_db_immich.sql
```

### Dawarich

```bash
zstd -d dawarich_db.sql.zstd
cat dawarich_db.sql | _ dce -T dawarich_db sh -c 'exec pg_restore --username=$POSTGRES_USER -d dawarich_development -c --if-exists -1'
```

To access the PostgreSQL CLI, run

```bash
_ dce dawarich_db sh -c 'exec psql --username=$POSTGRES_USER'
```
