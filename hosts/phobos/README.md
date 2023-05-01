# Phobos

## Restore Healthchecks database

This this inside the `~/healthchecks/docker` folder.

```bash
_ dce -T db sh -c 'pg_restore -U postgres -v -d $POSTGRES_DB' < ./healthchecks_db.sql
```
