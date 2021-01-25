# Diogo's Dotfiles

These are my dotfiles for my Arch Linux setup.

## Installation

Clone the repo and use stow (or create symlinks) to link to the correct directories.

### Ignored files

Below is a list of the files that are in `.gitignore`
(because they might contain sensitive information) and how to configure them.

- `awesome/.config/awesome/configuration/config.lua`: sample in `config.sample.lua`
- `awesome/.config/awesome/configuration/user-profile/*.png`: picture for theme; file name must match username

## Packages

The following packages were used:

| Name                                          | Package Manager | Description                                       | Used by                                      |
| :-------------------------------------------- | :-------------- | :------------------------------------------------ | -------------------------------------------- |
| `awesome-git`                                 | `yay`           | Window Manager                                    | Awesome config                               |
| `rofi`                                        | `pacman`        | App Launcher                                      | Awesome                                      |
| `picom-git`                                   | `yay`           | Compositor for X11                                | Awesome blur                                 |
| `inter-font`                                  | `pacman`        | Font                                              | Awesome                                      |
| `light-git`                                   | `yay`           | Brightness control app                            | Awesome brightness widget                    |
| `alsa-utils`, `pulseaudio`, `pulseaudio-alsa` | `pacman`        | Audio support                                     | Awesome volume widget                        |
| `acpi`, `acpid`, `acpi_call`                  | `pacman`        | Show battery status. For laptops only             | Awesome power/battery widget                 |
| `mpd`, `mpc`                                  | `pacman`        | Music player                                      | Awesome music widget                         |
| `feh`                                         | `pacman`        | Image viewer and wallpaper setter                 | Awesome wallpapers                           |
| `flameshot`                                   | `pacman`        | Screenshot tools                                  | Awesome screenshot                           |
| `xorg-xprop`                                  | `pacman`        | Property displayer for X                          | Awesome custom titlebars for each client     |
| `imagemagick`                                 | `pacman`        | Image viewing/manipulation                        | Awesome music widget album covers            |
| `blueman`                                     | `pacman`        | Bluetooth management                              | Awesome bluetooth widget                     |
| `redshift`                                    | `pacman`        | Color temperature of display                      | Awesome blue light widget                    |
| `xfce4-power-manager`                         | `pacman`        | Manages Power                                     | Awesome default launch app for batter widget |
| `upower`                                      | `pacman`        | Battery CLI tool                                  | Awesome battery widget                       |
| `noto-fonts-emoji`                            | `pacman`        | Google Noto emoji fonts                           | Awesome emoji support for notifications      |
| `nerd-fonts-fantasque-sans-mono`              | `yay`           | Another font                                      | Rofi unicode font                            |
| `xdg-user-dirs`                               | `pacman`        | Manages home folders for Pictures, Downloads, etc | Awesome various features                     |
| `iproute2`, `iw`                              | `pacman`        | Manage network connection                         | Awesome network widget                       |
| `ffmpeg`                                      | `pacman`        | Video recorder, converter, etc                    | Awesome screen recorder widget               |
| `dolphin`                                     | `pacman`        | File explorer                                     | File explorer                                |
| `gnome-keyring`                               | `pacman`        | Keyring                                           | Keyring                                      |

### Lua PAM

For the AwesomeWM lockscreen, you need to install `lua-pam`.
However, since you must change the lua version it is compiled against, you must clone the [`lua-pam` GitHub repository](https://github.com/rmtt/lua-pam).
Then, change the `CMakeLists.txt` file:

```
cmake_minimum_required(VERSION 3.15)
project(lua_pam)

set(CMAKE_CXX_STANDARD 14)
set(SOURCE_DIR src)

include_directories(/usr/include/lua5.3)

add_library(lua_pam SHARED ${SOURCE_DIR}/main.cpp)
target_link_libraries(lua_pam lua5.3 pam)
```

Make sure you have `lua53` installed (from `pacman`).
Finally, copy the `build/liblua_pam.so` file to `/usr/lib/lua-pam/`.

## Credits

- AwesomeWM Configuration from [`the-glorious-dotfiles`](https://github.com/manilarome/the-glorious-dotfiles). Modified by me.
- Background Images from Unsplash and Reddit
