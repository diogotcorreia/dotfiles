# Phobos

## Server Setup

1. Create a Debian 9 VM on Okeanos.
2. Upgrade CA certificates (`sudo apt update && sudo apt install ca-certificates`),
   since they are too old to download stuff from the web.
3. Install curl (`sudo apt install curl`).
4. Add ssh key to `/root/.ssh/authorized_keys`.
5. Run the [nixos-infect script](https://github.com/elitak/nixos-infect) as a root.
6. Deploy flake configuration (`sudo nixos-rebuild switch ...`).
7. Restore state from backup

P4GtnbMFVO

## Restore Healthchecks database

This this inside the `~/healthchecks/docker` folder.

```bash
_ dce -T db sh -c 'pg_restore -U postgres -v -d $POSTGRES_DB' < ./healthchecks_db.sql
```
