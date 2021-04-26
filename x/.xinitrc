#!/bin/sh

# Source xprofile
[ -f /etc/xprofile ] && . /etc/xprofile
[ -f ~/.xprofile ] && . ~/.xprofile

# Unlock keyring
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK

dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY

# Enable transparency theme in Qt5 apps
export XDG_SESSION_TYPE=x11
export QT_QPA_PLATFORMTHEME="qt5ct"

setxkbmap -layout pt                                    # Set keyboard layout to PT
numlockx &                                              # Turn on numlock
[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap               # Load custom key mapping

# if dwm exits 0, restart -- this allows hot reloading of config.h
while type dwm >/dev/null ; do dwm && continue || break ; done
