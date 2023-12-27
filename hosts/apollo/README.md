# Apollo

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
nix run github:numtide/nixos-anywhere -- --extra-files $TEMP --flake github:diogotcorreia/dotfiles#bro root@bro
```
