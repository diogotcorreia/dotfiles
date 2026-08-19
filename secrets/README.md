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
However, age needs to know the currently connected YubiKey:

```fish
agenix -e <path/to/.age/file> -i (age-plugin-yubikey -i --slot 1 | psub)
```
