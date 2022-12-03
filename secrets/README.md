# Secret Management

Secrets are managed by [Agenix](https://github.com/ryantm/agenix).

## Adding a new secret

To add a new secret, follow these two steps:

1. Create an entry on `secrets.nix`. This file is only used by the `agenix` executable
   to know which keys to encrypt it with.
2. Open the editor to add the content to want to encrypt:

   ```
   agenix -e <path/to/.age/file>
   ```

## Editing a secret

The process is the same as step 2 of creating a new secret.
However, since the private key might only be accessible to root,
we might need to run the command as sudo.
