# Diogo's NixOS Flakes Configuration

_Looking for my old ArchLinux dotfiles? Check out the [`archlinux` branch](https://github.com/diogotcorreia/dotfiles/tree/archlinux)._

---

This flake handles the configuration for a single-user personal computer
and server setups.

It is mainly structured into 6 different folders:

- `hosts`: Files defining available hosts.
  Each host can be defined by creating a `.nix` file or folder
  with its hostname.
  If the host is defined through a folder, all files in that folder
  are included in the host's definition, with the exception of the
  `configuration.nix` file, which can be used to configure the properties
  of the host, such as its architecture (e.g., `x86_64-linux`);
- `modules`: Modules that can be enabled and configured through options.
- `profiles`: Profiles don't have any options and can be imported into
  each hosts' configuration through the `profiles` argument.
- `lib`: Helper functions and attributes.
- `packages`: Package definitions of packages that are not available in nixpkgs,
  made available in `pkgs.my`.
- `overlays`: Overlays to nixpkgs, where each file is automatically applied.

Some highlights of things that exist and/or are configured in this flake are:

- [Home Manager](https://github.com/nix-community/home-manager/)
- Root on tmpfs
- dwm, dmenu, dwmblocks and slock
- neovim
- Router with VLANs
- Agenix
- Healthchecks.io pinging
- Restic backups
- Nebula VPN
- CI build of hosts' configuration with push to cache server

## References

I took inspiration from the following configurations when building mine:

- [RageKnify/Config](https://github.com/RageKnify/Config)
- [luishfonseca/dotfiles](https://github.com/luishfonseca/dotfiles)
- [EdSwordsmith/dotfiles](https://github.com/EdSwordsmith/dotfiles)
- [rnl-dei/nixrnl](https://github.com/rnl-dei/nixrnl)
