# Diogo's Dotfiles

These are my dotfiles for my Arch Linux setup.

## Installation

Clone the repo and use stow (or create symlinks) to link to the correct directories.

## Packages

I use the following packages in my system. Not all of them are required to use my DWM setup.

- AUR: Arch User Repository
- APKG: Arch Official Packages

| Name                                                 | Package Source | Description                                       | Used by                              |
| :--------------------------------------------------- | :------------- | :------------------------------------------------ | ------------------------------------ |
| `stow`                                               | APKG           | Create symlinks for dotfiles                      | -                                    |
| `xorg-server`, `xorg-xinit`                          | APKG           | X11 server                                        | -                                    |
| `picom-git`                                          | AUR            | Compositor for X11                                | Awesome blur                         |
| `alsa-utils`, `pulseaudio`, `pulseaudio-alsa`        | APKG           | Audio support                                     | DWM volume keys                      |
| `pamixer`                                            | APKG           | Pulseaudio CLI mixer                              | DWM sb-audio widget                  |
| `feh`                                                | APKG           | Image viewer and wallpaper setter                 | Wallpaper script (`setbg`)           |
| `flameshot`                                          | APKG           | Screenshot tools                                  | Screenshot keybind <kbd>prt sc</kbd> |
| `redshift`                                           | APKG           | Color temperature of display                      | -                                    |
| `xdg-user-dirs`                                      | APKG           | Manages home folders for Pictures, Downloads, etc | -                                    |
| `gnome-keyring`                                      | APKG           | Keyring                                           | -                                    |
| `alacritty`                                          | APKG           | Terminal                                          | DWM default terminal                 |
| `playerctl`                                          | APKG           | Media Player Controller                           | DWM Keyboard media keys              |
| `libxft-bgra`                                        | AUR            | Patched libxft-bgra for colored emoji             | DWM Statusbar                        |
| `cronie`                                             | APKG           | Crontab                                           | DWM Statusbar Pacman Updates         |
| `clipmenu`                                           | APKG           | Clipboard Manager                                 | -                                    |
| `lf` (or `lf-bin`)                                   | AUR            | Terminal File Manager                             | -                                    |
| `zsh`                                                | APKG           | Shell                                             | -                                    |
| `oh-my-zsh`                                          | Custom Script  | Framework for zsh                                 | -                                    |
| `autojump`                                           | AUR            | cd into directories by fuzzy search               | autojump zsh plugin                  |
| `zathura`, `zathura-pdf-mupdf`                       | APKG           | PDF Reader                                        | -                                    |
| `xlayoutdisplay`                                     | AUR            | Wrapper for xrandr to auto setup multihead        | -                                    |
| `numlockx`                                           | APKG           | Change <kdb>numlock</kdb> status                  | Turn on numlock on login             |
| `blueman`                                            | APKG           | Bluetooth management                              | -                                    |
| `noto-fonts`, `noto-fonts-emoji`, `noto-fonts-extra` | APKG           | Google Noto Fonts                                 | -                                    |
| `ttf-meslo-nerd-font-powerlevel10k`                  | AUR            | Font for oh-my-zsh theme                          | Powerlevel10k theme                  |
| `ttf-fira-code`                                      | APKG           | Fira Code Mono Font                               | DWM font                             |
| `ttf-joypixels`                                      | APKG           | JoyPixels font                                    | -                                    |
| `ttf-font-awesome`                                   | APKG           | Font Awesome 5 (Solid)                            | DWM Statusbar Font Icons             |

Inside the `suckless` folder are some programs that need to be compiled (`dwm`, `dmenu`, `dwmblocks` and `slock`).

### Statusbar configuration

Below is a list of statusbar modules that need extra configuration.  
Instructions are in the respective bash files, under `x/.local/bin/statusbar`.

- `sb-pacpackages`

### Lockscreen Configuration

My setup uses [`slock`](https://tools.suckless.org/slock/), which drops privileges to
a certain user and group when locked.

### Redshift

Redshift is started along with X. However, it might need to be configured to work
for your location. Configuration files are not included in this repo to avoid sharing
location coordinates.

Put the following in your `~/.config/redshift/redshift.conf` (from ArchWiki):

```conf
[redshift]
...
; Set the location-provider: 'geoclue2', 'manual'
; type 'redshift -l list' to see possible values.
; The location provider settings are in a different section.
location-provider=manual

...

; Keep in mind that longitudes west of Greenwich (e.g. the Americas)
; are negative numbers.
[manual]
lat=48.864716
lon=2.349014
```

## Credits

- AwesomeWM Configuration from [`the-glorious-dotfiles`](https://github.com/manilarome/the-glorious-dotfiles). Modified by me.
- Background Images from Unsplash and Reddit
- [dwmblocks](https://github.com/LukeSmithxyz/dwmblocks) by LukeSmithxyz along with his [statusbar scripts](https://github.com/LukeSmithxyz/voidrice/tree/master/.local/bin/statusbar)
